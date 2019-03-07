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

func processArguments(arguments: ArgumentParser.Result) throws {
  let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

  let captionsFile = arguments.get(captionsPath)!
  let captionsFileURL = currentDirectoryURL.appendingPathComponent(captionsFile)
  let captionsString = try String(contentsOf: captionsFileURL, encoding: .utf8)
  let captions = try parseCaptions(captionsString)

  let descriptionConfigFile = arguments.get(descriptionConfigPath)!
  let descriptionConfigFileURL = currentDirectoryURL.appendingPathComponent(descriptionConfigFile)
  let descriptionConfigString = try String(contentsOf: descriptionConfigFileURL, encoding: .utf8)
  let descriptionConfig = try DescriptionConfig.from(json: descriptionConfigString)

  let generatorConfigFile = arguments.get(generatorConfigPath)!
  let generatorConfigFileURL = currentDirectoryURL.appendingPathComponent(generatorConfigFile)
  let generatorConfigString = try String(contentsOf: generatorConfigFileURL, encoding: .utf8)
  let generatorConfig = try GeneratorConfig.from(json: generatorConfigString)

  let outputDir = arguments.get(outputDirPath)!
  let outputDirURL = currentDirectoryURL.appendingPathComponent(outputDir)  
  let outputRequestedCaptionsFileURL = outputDirURL.appendingPathComponent("requested_captions.txt")
  let outputFullCaptionsFileURL = outputDirURL.appendingPathComponent("full_captions.txt")
  let outputSVGDirURL = outputDirURL.appendingPathComponent("svg")

  // First we clean the output directory.
  try FileManager.default.removeItem(at: outputDirURL)
  try FileManager.default.createDirectory(
    at: outputSVGDirURL, 
    withIntermediateDirectories: true,
    attributes: nil)
  
  var generator = Generator()
  var requestedCaptions = [String]()
  var fullCaptions = [String]()
  requestedCaptions.reserveCapacity(captions.count * generatorConfig.numImagesPerCaption)
  fullCaptions.reserveCapacity(captions.count * generatorConfig.numImagesPerCaption)
  var i = 0
  for (c, caption) in captions.enumerated() {
    let captionString = caption.map { $0.caption } .joined(separator: ", ")
    print("Generating images for caption \(c) / \(captions.count): \(captionString).")
    for _ in 0..<generatorConfig.numImagesPerCaption {
      let image = generator.generateImage(
        for: caption, 
        generatorConfig: generatorConfig,
        descriptionConfig: descriptionConfig)
      requestedCaptions.append(image.requestedCaption)
      fullCaptions.append(image.fullCaption)
      try image.svg.write(
        to: outputSVGDirURL.appendingPathComponent("\(i).svg"),
        atomically: false,
        encoding: .utf8)
      i += 1
    }
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
}

do {
  let parsedArguments = try parser.parse(arguments)
  try processArguments(arguments: parsedArguments)
} catch let error as ArgumentParserError {
  print(error.description)
} catch DataError.invalidShape(let shape) {
  print("Invalid shape: \(shape)")
} catch let error {
  print(error.localizedDescription)
}
