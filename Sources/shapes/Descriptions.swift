import Foundation

public struct DescriptionConfig : Codable {
  let polygonApproxNumVertices: Int

  let rotationRange: ClosedRange<Double>
  let triangleWidthRange: ClosedRange<Double>
  let triangleHeightRange: ClosedRange<Double>
  let squareSizeRange: ClosedRange<Double>
  let rectangleWidthRange: ClosedRange<Double>
  let rectangleHeightRange: ClosedRange<Double>
  let pentagonSizeRange: ClosedRange<Double>
  let crossWidthRange: ClosedRange<Double>
  let crossHeightRange: ClosedRange<Double>
  let crossThicknessRange: ClosedRange<Double>
  let circleRadiusRange: ClosedRange<Double>
  let semiCircleRadiusRange: ClosedRange<Double>
  let ellipseHorizontalRadiusRange: ClosedRange<Double>
  let ellipseVerticalRadiusRange: ClosedRange<Double>

  public static func from(json: String) throws -> DescriptionConfig {
    let jsonDecoder = JSONDecoder()
    return try jsonDecoder.decode(DescriptionConfig.self, from: json.data(using: .utf8)!)
  }
}

public extension DescriptionConfig {
  func toJson(pretty: Bool = true) throws -> String {
    let encoder = JSONEncoder()
    if pretty {
      encoder.outputFormatting = .prettyPrinted
    }
    let data = try encoder.encode(self)
    return String(data: data, encoding: .utf8)!
  }
}

public protocol Description {
  var color: Color? { get }
  var caption: String { get }

  func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape?
}

internal extension Description {
  func rotateShape(
    _ shape: Shape,
    rotationRange: ClosedRange<Double>?,
    generator: inout Generator
  ) -> Shape {
    let a = Double.random(in: rotationRange ?? 0.0...360.0, using: &generator.rng)
    return shape.rotate(by: a)
  }

  func positionShape(
    _ shape: Shape,
    config: GeneratorConfig,
    generator: inout Generator
  ) -> Shape? {
    let boundingBox = shape.boundingBox()
    let width = boundingBox.right - boundingBox.left
    let height = boundingBox.bottom - boundingBox.top
    let minX = -boundingBox.left
    let minY = -boundingBox.top
    let maxX = abs(config.width - boundingBox.right)
    let maxY = abs(config.height - boundingBox.bottom)
    if config.width < width || config.height < height {
      return nil
    }
    let p = Point(
      Double.random(in: minX...maxX, using: &generator.rng),
      Double.random(in: minY...maxY, using: &generator.rng))
    return shape.move(by: p)
  }
}

public class TriangleDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) triangle"
    } else {
      return "triangle"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let w = Double.random(in: descriptionConfig.triangleWidthRange, using: &generator.rng)
    let h = Double.random(in: descriptionConfig.triangleHeightRange, using: &generator.rng)
    var shape: Shape = ConvexPolygon(
      vertices: [
        Point(0.0, h),
        Point(w, h),
        Point(w / 2.0, 0.0)])
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class SquareDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) square"
    } else {
      return "square"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let s = Double.random(in: descriptionConfig.squareSizeRange, using: &generator.rng)
    var shape: Shape = ConvexPolygon(vertices: [
      Point(0.0, 0.0),
      Point(0.0, s),
      Point(s, s),
      Point(s, 0.0)])
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class RectangleDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) rectangle"
    } else {
      return "rectangle"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let w = Double.random(in: descriptionConfig.rectangleWidthRange, using: &generator.rng)
    let h = Double.random(in: descriptionConfig.rectangleHeightRange, using: &generator.rng)
    var shape: Shape = ConvexPolygon(
      vertices: [
        Point(0.0, 0.0),
        Point(0.0, h),
        Point(w, h),
        Point(w, 0.0)])
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class PentagonDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) pentagon"
    } else {
      return "pentagon"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    var shape: Shape = ConvexPolygon(vertices: [
      Point(0.000000, 0.363271),
      Point(0.190983, 0.951056),
      Point(0.809017, 0.951056),
      Point(1.000000, 0.363271),
      Point(0.500000, 0.000000)])
    let s = Double.random(in: descriptionConfig.pentagonSizeRange, using: &generator.rng)
    shape = shape.scale(by: s)
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class CrossDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) cross"
    } else {
      return "cross"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let w = Double.random(in: descriptionConfig.crossWidthRange, using: &generator.rng)
    let h = Double.random(in: descriptionConfig.crossHeightRange, using: &generator.rng)
    let t = Double.random(in: descriptionConfig.crossThicknessRange, using: &generator.rng)
    var shape: Shape = ConvexPolygon(
      vertices: [
        Point((w - t) / 2.0, 0.0),
        Point((w - t) / 2.0, (h - t) / 2.0),
        Point(0.0, (h - t) / 2.0),
        Point(0.0, (h + t) / 2.0),
        Point((w - t) / 2.0, (h + t) / 2.0),
        Point((w - t) / 2.0, h),
        Point((w + t) / 2.0, h),
        Point((w + t) / 2.0, (h + t) / 2.0),
        Point(w, (h + t) / 2.0),
        Point(w, (h - t) / 2.0),
        Point((w + t) / 2.0, (h - t) / 2.0),
        Point((w + t) / 2.0, 0.0)])
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class CircleDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) circle"
    } else {
      return "circle"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let r = Double.random(in: descriptionConfig.circleRadiusRange, using: &generator.rng)
    let shape: Shape = Circle(
      radiusSegment: Line(Point(0.0, 0.0), Point(r, 0.0)),
      polygonNumVertices: descriptionConfig.polygonApproxNumVertices)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class SemiCircleDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) semicircle"
    } else {
      return "semicircle"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let r = Double.random(in: descriptionConfig.semiCircleRadiusRange, using: &generator.rng)
    var shape: Shape = SemiCircle(
      radiusSegment: Line(Point(0.0, 0.0), Point(r, 0.0)),
      polygonNumVertices: descriptionConfig.polygonApproxNumVertices)
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}

public class EllipseDescription : Description {
  public let color: Color?

  public init(color: Color?) {
    self.color = color
  }

  public lazy var caption: String = {
    [unowned self] in
    if let c = self.color {
      return "\(c.rawValue) ellipse"
    } else {
      return "ellipse"
    }
  }()

  public func sampleShape(
    descriptionConfig: DescriptionConfig,
    generatorConfig: GeneratorConfig,
    generator: inout Generator
  ) -> ColoredShape? {
    let hr = Double.random(in: descriptionConfig.ellipseHorizontalRadiusRange, using: &generator.rng)
    let vr = Double.random(in: descriptionConfig.ellipseVerticalRadiusRange, using: &generator.rng)
    var shape: Shape = Ellipse(
      at: Point(0.0, 0.0),
      horizontalRadius: hr,
      verticalRadius: vr,
      rotationAngle: 0.0,
      polygonNumVertices: descriptionConfig.polygonApproxNumVertices)
    shape = self.rotateShape(shape, rotationRange: descriptionConfig.rotationRange, generator: &generator)
    let color = self.color ?? generator.sampleColor()
    if let s = self.positionShape(shape, config: generatorConfig, generator: &generator) {
      return (shape: s, color: color, caption: self.caption)
    } else {
      return nil
    }
  }
}
