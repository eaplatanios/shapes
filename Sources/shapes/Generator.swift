import Foundation

public typealias Caption = [Description]
public typealias GeneratedImage = (svg: String, requestedCaption: String, fullCaption: String)

public struct GeneratorConfig : Codable {
  let width: Double
  let height: Double
  let backgroundColor: Color
  let numImagesPerCaption: Int

  let shuffleDescriptions: Bool
  let maxOverlapRatio: Double

  let minNumRandomShapes: Int
  let maxNumRandomShapes: Int

  public static func from(json: String) throws -> GeneratorConfig {
    let jsonDecoder = JSONDecoder()
    return try jsonDecoder.decode(GeneratorConfig.self, from: json.data(using: .utf8)!)
  }
}

public extension GeneratorConfig {
  func toJson(pretty: Bool = true) throws -> String {
    let encoder = JSONEncoder()
    if pretty {
      encoder.outputFormatting = .prettyPrinted
    }
    let data = try encoder.encode(self)
    return String(data: data, encoding: .utf8)!
  }
}

public struct Generator {
  internal var rng: PhiloxRandomNumberGenerator

  public init(seed: UInt64? = nil) {
    if let s = seed {
      self.rng = PhiloxRandomNumberGenerator(uint64Seed: s)
    } else {
      self.rng = PhiloxRandomNumberGenerator.global
    }
  }

  public mutating func generateImage(
    for caption: Caption,
    generatorConfig: GeneratorConfig,
    descriptionConfig: DescriptionConfig
   ) -> GeneratedImage {
    var shuffledDescriptions = [Description]()
    let numRandomImages = Int.random(
      in: generatorConfig.minNumRandomShapes..<generatorConfig.maxNumRandomShapes, 
      using: &rng)
    for _ in 0..<numRandomImages {
      shuffledDescriptions.append(self.sampleDescription())
    }
    shuffledDescriptions.append(
      contentsOf: generatorConfig.shuffleDescriptions ? caption.shuffled() : caption)
    var shapes = [ColoredShape]()
    var i = 0
    while i < shuffledDescriptions.count {
      let shape = shuffledDescriptions[i].sampleShape(
        descriptionConfig: descriptionConfig,
        generatorConfig: generatorConfig,
        generator: &self)
      if (shape == nil || !checkShape(
          shape: shape!, 
          existingShapes: shapes, 
          maxOverlapRatio: generatorConfig.maxOverlapRatio)) {
        shapes.removeAll()
        i = 0
      } else {
        shapes.append(shape!)
        i += 1
      }
    }
    let svg = """
      <svg 
        xmlns="http://www.w3.org/2000/svg"
        width="\(generatorConfig.width)" 
        height="\(generatorConfig.height)" 
        viewBox="0 0 \(generatorConfig.width) \(generatorConfig.height)" 
        style="background-color: \(generatorConfig.backgroundColor.rawValue)">
        \(shapes.map { $0.shape.svg(color: $0.color) } .joined())
      </svg>
      """
    let requestedCaption = caption.map { $0.caption } .joined(separator: ", ")
    let fullCaption = shapes.map { $0.caption } .joined(separator: ", ")
    return (svg: svg, requestedCaption: requestedCaption, fullCaption: fullCaption)
   }

  internal func checkShape(
    shape: ColoredShape, 
    existingShapes: [ColoredShape],
    maxOverlapRatio: Double? = nil
  ) -> Bool {
    if let maxOverlap = maxOverlapRatio {
      let shapeBB = shape.shape.circumscribedConvexPolygon()
      for existingShape in existingShapes {
        let overlapRatio = shapeBB.intersectionRatio(
          with: existingShape.shape.circumscribedConvexPolygon())
        if overlapRatio > maxOverlap {
          return false
        }
      }
    }
    return true
  }

  internal mutating func sampleDescription() -> Description {
    let color = self.sampleColor()
    switch Int.random(in: 0..<8, using: &rng) {
      case 0: return TriangleDescription(color: color)
      case 1: return SquareDescription(color: color)
      case 2: return RectangleDescription(color: color)
      case 3: return PentagonDescription(color: color)
      case 4: return CrossDescription(color: color)
      case 5: return CircleDescription(color: color)
      case 6: return SemiCircleDescription(color: color)
      case 7: return EllipseDescription(color: color)
      default: fatalError("Unreachable.")
    }
  }

  internal mutating func sampleColor() -> Color {
    let colors: [Color] = [.red, .green, .blue, .yellow, .magenta, .cyan, .gray]
    let index = Int.random(in: 0..<colors.count, using: &rng)
    return colors[index]
  }
}
