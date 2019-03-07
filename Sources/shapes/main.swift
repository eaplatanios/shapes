import Foundation
import Utility

// The first argument is always the executable, and so we drop it.
let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

let parser = ArgumentParser(
  usage: "<options>",
  overview: """
    This tool can be used to generate randomized images 
    with colored shapes according to some provided descriptions.
    """)
let captionsPath: OptionArgument<String> = parser.add(
  option: "--captions",
  shortName: "-c",
  kind: String.self,
  usage: "Path to the file containing the image captions.")
let descriptionConfigPath: OptionArgument<String> = parser.add(
  option: "--description-config",
  shortName: "-dc",
  kind: String.self,
  usage: "Path to the file containing the descriptions configuration.")
let generatorConfigPath: OptionArgument<String> = parser.add(
  option: "--generator-config",
  shortName: "-gc",
  kind: String.self,
  usage: "Path to the file containing the generator configuration.")
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

  let captionsFile = parsedArguments.get(captionsPath)!
  let captionsFileURL = currentDirectoryURL.appendingPathComponent(captionsFile)
  let captionsString = try String(contentsOf: captionsFileURL, encoding: .utf8)
  let captions = try parseCaptions(captionsString)

  let descriptionConfigFile = parsedArguments.get(descriptionConfigPath)!
  let descriptionConfigFileURL = currentDirectoryURL.appendingPathComponent(descriptionConfigFile)
  let descriptionConfigString = try String(contentsOf: descriptionConfigFileURL, encoding: .utf8)
  let descriptionConfig = try DescriptionConfig.from(json: descriptionConfigString)

  let generatorConfigFile = parsedArguments.get(generatorConfigPath)!
  let generatorConfigFileURL = currentDirectoryURL.appendingPathComponent(generatorConfigFile)
  let generatorConfigString = try String(contentsOf: generatorConfigFileURL, encoding: .utf8)
  let generatorConfig = try GeneratorConfig.from(json: generatorConfigString)

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
  let n = captions.count * generatorConfig.numImagesPerCaption
  var requestedCaptions = Array(repeating: "", count: n)
  var fullCaptions = Array(repeating: "", count: n)
  DispatchQueue.concurrentPerform(iterations: captions.count) { c in
    let caption = captions[c]
    let captionString = caption.map { $0.caption } .joined(separator: ", ")
    print("Generating images for caption \(c) / \(captions.count): \(captionString).")
    for j in 0..<generatorConfig.numImagesPerCaption {
      let image = generator.generateImage(
        for: caption, 
        generatorConfig: generatorConfig,
        descriptionConfig: descriptionConfig)
      let i = c * generatorConfig.numImagesPerCaption + j
      requestedCaptions[i] = image.requestedCaption
      fullCaptions[i] = image.fullCaption
      do {
        let svgFileURL = outputSVGDirURL.appendingPathComponent("\(i).svg")
        try image.svg.write(
          to: svgFileURL,
          atomically: false,
          encoding: .utf8)
        if parsedConvertToPng {
          let pngFileURL = outputPNGDirURL.appendingPathComponent("\(i).png")
          let process = Process()
          process.environment = ProcessInfo.processInfo.environment
          process.launchPath = "/bin/bash"
          process.arguments = [
            "-c", """
              rsvg-convert \
                -w \(Int(generatorConfig.width)) \
                -h \(Int(generatorConfig.height)) \
                -b \(generatorConfig.backgroundColor.rawValue) \
                \(svgFileURL.path) \
                -o \(pngFileURL.path)
              """]
          process.launch()
          process.waitUntilExit()
        }
      } catch DataError.invalidShape(let shape) {
        print("Invalid shape: \(shape)")
      } catch let error {
        print(error.localizedDescription)
      }
    }
    print("Generated images for caption \(c) / \(captions.count): \(captionString).")
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
