// Copyright 2019, Emmanouil Antonios Platanios. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

import Foundation
import SPMUtility

// The first argument is always the executable, and so we drop it.
let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

let parser = ArgumentParser(
  usage: "<options>",
  overview: """
    This tool can be used to generate randomized images 
    with colored shapes according to some provided descriptions.
    """)
let configurationPath: OptionArgument<String> = parser.add(
  option: "--configuration",
  shortName: "-c",
  kind: String.self,
  usage: "Path to the file containing the configuration.")
let descriptionsPath: OptionArgument<String> = parser.add(
  option: "--descriptions",
  shortName: "-d",
  kind: String.self,
  usage: "Path to the file containing the image descriptions.")
let captionsPath: OptionArgument<String> = parser.add(
  option: "--captions",
  shortName: "-c",
  kind: String.self,
  usage: "Path to the file containing the image captions.")
let outputDirPath: OptionArgument<String> = parser.add(
  option: "--output-dir",
  shortName: "-o",
  kind: String.self,
  usage: "Path to the directory where the generated images will be saved.")
let convertToPng: OptionArgument<Bool> = parser.add(
  option: "--convert-to-png",
  kind: Bool.self,
  usage: "Boolean value indicating whether to convert the output SVG images to PNG.")

do {
  let parsedArguments = try parser.parse(arguments)
  let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

  let configurationFile = parsedArguments.get(configurationPath)!
  let configurationFileURL = currentDirectoryURL.appendingPathComponent(configurationFile)
  let configurationString = try String(contentsOf: configurationFileURL, encoding: .utf8)
  let configuration = try Configuration.from(json: configurationString)

  let descriptions = try { () -> [[Description]] in
    if let descriptionsFile = parsedArguments.get(descriptionsPath) {
      let descriptionsFileURL = currentDirectoryURL.appendingPathComponent(descriptionsFile)
      let descriptionsString = try String(contentsOf: descriptionsFileURL, encoding: .utf8)
      return try JSONDecoder().decode(
        [[AnyDescription]].self,
        from: descriptionsString.data(using: .utf8)!
      ).map { $0.map { $0.base } }
    } else {
      if let captionsFile = parsedArguments.get(captionsPath) {
        let captionsFileURL = currentDirectoryURL.appendingPathComponent(captionsFile)
        let captionsString = try String(contentsOf: captionsFileURL, encoding: .utf8)
        return try parseCaptions(captionsString, for: configuration)
      } else {
        print("ERROR: Either a descriptions file or a captions file must be provided.")
        exit(1)
      }
    }
  }()

  let outputDir = parsedArguments.get(outputDirPath)!
  let outputDirURL = currentDirectoryURL.appendingPathComponent(outputDir)  
  let outputRequestedCaptionsFileURL = outputDirURL.appendingPathComponent("requested_captions.txt")
  let outputFullCaptionsFileURL = outputDirURL.appendingPathComponent("full_captions.txt")
  let outputSVGDirURL = outputDirURL.appendingPathComponent("svg")
  let outputPNGDirURL = outputDirURL.appendingPathComponent("png")

  let parsedConvertToPng = parsedArguments.get(convertToPng) ?? false

  // First we clean the output directory.
  if FileManager.default.fileExists(atPath: outputDirURL.path) {
    try FileManager.default.removeItem(at: outputDirURL)
  }

  try FileManager.default.createDirectory(
    at: outputSVGDirURL, 
    withIntermediateDirectories: true,
    attributes: nil)
  if parsedConvertToPng {
    try FileManager.default.createDirectory(
      at: outputPNGDirURL, 
      withIntermediateDirectories: true,
      attributes: nil)
  }
  
  var generator = Generator()
  let n = descriptions.count * configuration.imageCountPerDescription
  var requestedCaptions = Array(repeating: "", count: n)
  var fullCaptions = Array(repeating: "", count: n)
  DispatchQueue.concurrentPerform(iterations: descriptions.count) { c in
    let description = descriptions[c]
    let caption = description.map {
      try! $0.caption ?? $0.toJson(pretty: false)
    }.joined(separator: ", ")
    print("Generating images for caption \(c + 1) / \(descriptions.count): \(caption).")
    for j in 0..<configuration.imageCountPerDescription {
      let image = generator.generateImage(for: description, configuration: configuration)
      let i = c * configuration.imageCountPerDescription + j
      requestedCaptions[i] = caption
      fullCaptions[i] = image.caption
      do {
        let svgFileURL = outputSVGDirURL.appendingPathComponent("\(i).svg")
        try image.svg.write(
          to: svgFileURL,
          atomically: false,
          encoding: .utf8)
      } catch DataError.invalidShape(let shape) {
        print("Invalid shape: \(shape)")
      } catch let error {
        print(error.localizedDescription)
      }
    }
    print("Generated images for caption \(c) / \(descriptions.count): \(caption).")
  }

  if parsedConvertToPng {
    print("Converting to PNG.")
    let process = Process()
    process.environment = ProcessInfo.processInfo.environment
    process.launchPath = "/bin/bash"
    process.arguments = [
      "-c", """
        for i in `find '\(outputSVGDirURL.path)' -name '*.svg' -exec basename {} \\;`; \
        do rsvg-convert \
          -w \(Int(configuration.width)) \
          -h \(Int(configuration.height)) \
          -b \(configuration.backgroundColor.rawValue) \
          '\(outputSVGDirURL.path)'/$i \
          -o '\(outputPNGDirURL.path)'/`echo $i | sed -e 's/svg$/png/'`; \
        done
        """]
    process.launch()
    process.waitUntilExit()
  }

  print("Saving the image captions.")
  try requestedCaptions.joined(separator: "\n").write(
    to: outputRequestedCaptionsFileURL,
    atomically: false,
    encoding: .utf8)
  try fullCaptions.joined(separator: "\n").write(
    to: outputFullCaptionsFileURL,
    atomically: false,
    encoding: .utf8)
  print("Finished generating images.")
  print("Output directory: \(outputDirURL.absoluteString).")
} catch let error as ArgumentParserError {
  print(error.description)
} catch DataError.invalidShape(let shape) {
  print("Invalid shape: \(shape)")
} catch let error {
  print(error.localizedDescription)
}
