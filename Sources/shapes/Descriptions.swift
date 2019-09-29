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

public typealias SampledShape = (shape: Shape, caption: String)
public typealias SampledColoredShape = (shape: Shape, color: Color, caption: String)

public protocol Description: Codable {
  static var type: DescriptionType { get }
  var allowedColors: [Color] { get set }
  var caption: String? { get set }
  func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape
}

extension Description {
  public func sampleColor<T: RandomNumberGenerator>(rng: inout T) -> Color {
    allowedColors[Int.random(in: 0..<allowedColors.count, using: &rng)]
  }

  public func sampleColoredShape<T: RandomNumberGenerator>(rng: inout T) -> SampledColoredShape {
    let (shape, caption) = sampleShape(rng: &rng)
    let color = sampleColor(rng: &rng)
    return (shape: shape, color: color, caption: "\(color.rawValue) \(caption)")
  }

  public func toJson(pretty: Bool = true) throws -> String {
    let encoder = JSONEncoder()
    if pretty {
      encoder.outputFormatting = .prettyPrinted
    }
    let data = try encoder.encode(self)
    return String(data: data, encoding: .utf8)!
  }
}

/// Type of a description. This is used to allow for encoding/decoding arrays containing
/// descriptions of multiple types.
public enum DescriptionType: String, Codable {
  case triangle, square, rectangle, pentagon, regularPolygon, cross, circle, semiCircle, ellipse

  internal var metaType: Description.Type {
    switch self {
    case .triangle: return TriangleDescription.self
    case .square: return SquareDescription.self
    case .rectangle: return RectangleDescription.self
    case .pentagon: return PentagonDescription.self
    case .regularPolygon: return RegularPolygonDescription.self
    case .cross: return CrossDescription.self
    case .circle: return CircleDescription.self
    case .semiCircle: return SemiCircleDescription.self
    case .ellipse: return EllipseDescription.self
    }
  }
}

/// Type-erased descriptions type used to allow for encoding/decoding arrays containing
/// descriptions of multiple types.
public struct AnyDescription: Codable {
  let base: Description

  public init(_ base: Description) {
    self.base = base
  }

  private enum CodingKeys: CodingKey {
    case type, base
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(DescriptionType.self, forKey: .type)
    self.base = try type.metaType.init(from: decoder)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type(of: base).type, forKey: .type)
    try base.encode(to: encoder)
  }
}

public struct TriangleDescription: Description {
  public static var type: DescriptionType = .triangle

  public let widthRange: ClosedRange<Double>
  public let heightRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    widthRange: ClosedRange<Double> = 0...1,
    heightRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.widthRange = widthRange
    self.heightRange = heightRange
    self.rotationRange = rotationRange
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let width = Double.random(in: widthRange, using: &rng)
    let height = Double.random(in: heightRange, using: &rng)
    let shape = ConvexPolygon(
      vertices: [
        Point(0.0, height),
        Point(width, height),
        Point(width / 2.0, 0.0)]
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "triangle")
  }
}

public struct SquareDescription: Description {
  public static var type: DescriptionType = .square

  public let sizeRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    sizeRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.sizeRange = sizeRange
    self.rotationRange = rotationRange
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let size = Double.random(in: sizeRange, using: &rng)
    let shape = ConvexPolygon(vertices: [
      Point(0.0, 0.0),
      Point(0.0, size),
      Point(size, size),
      Point(size, 0.0)]
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "square")
  }
}

public struct RectangleDescription: Description {
  public static var type: DescriptionType = .rectangle

  public let widthRange: ClosedRange<Double>
  public let heightRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    widthRange: ClosedRange<Double> = 0...1,
    heightRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.widthRange = widthRange
    self.heightRange = heightRange
    self.rotationRange = rotationRange
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let width = Double.random(in: widthRange, using: &rng)
    let height = Double.random(in: heightRange, using: &rng)
    let shape = ConvexPolygon(
      vertices: [
        Point(0.0, 0.0),
        Point(0.0, height),
        Point(width, height),
        Point(width, 0.0)]
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "rectangle")
  }
}

public struct PentagonDescription: Description {
  public static var type: DescriptionType = .pentagon

  public let sizeRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    sizeRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.sizeRange = sizeRange
    self.rotationRange = rotationRange
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let size = Double.random(in: sizeRange, using: &rng)
    let shape = ConvexPolygon(vertices: [
      Point(0.000000, 0.363271),
      Point(0.190983, 0.951056),
      Point(0.809017, 0.951056),
      Point(1.000000, 0.363271),
      Point(0.500000, 0.000000)]
    ).scaled(by: size).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "pentagon")
  }
}

public struct RegularPolygonDescription: Description {
  public static var type: DescriptionType = .regularPolygon

  public let vertexCountRange: ClosedRange<Int>
  public let sizeRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    vertexCountRange: ClosedRange<Int>,
    sizeRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.vertexCountRange = vertexCountRange
    self.sizeRange = sizeRange
    self.rotationRange = rotationRange
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let vertexCount = Int.random(in: vertexCountRange, using: &rng)
    let size = Double.random(in: sizeRange, using: &rng)
    let a = 2 * Double.pi / Double(vertexCount)
    let r = 1.0 / cos(a / 2)
    var vertices = [Point]()
    vertices.reserveCapacity(vertexCount)
    var theta = 0.0
    for _ in 0..<vertexCount {
      let x = r * cos(theta)
      let y = r * sin(theta)
      vertices.append(Point(x, y))
      theta -= a
    }
    let shape = ConvexPolygon(
      vertices: vertices
    ).scaled(by: size).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "polygon[\(vertexCount)]")
  }
}

public struct CrossDescription: Description {
  public static var type: DescriptionType = .cross

  public let widthRange: ClosedRange<Double>
  public let heightRange: ClosedRange<Double>
  public let thicknessRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    widthRange: ClosedRange<Double> = 0...1,
    heightRange: ClosedRange<Double> = 0...1,
    thicknessRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.widthRange = widthRange
    self.heightRange = heightRange
    self.thicknessRange = thicknessRange
    self.rotationRange = rotationRange
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let width = Double.random(in: widthRange, using: &rng)
    let height = Double.random(in: heightRange, using: &rng)
    let thickness = Double.random(in: thicknessRange, using: &rng)
    let shape = ConvexPolygon(
      vertices: [
        Point((width - thickness) / 2.0, 0.0),
        Point((width - thickness) / 2.0, (height - thickness) / 2.0),
        Point(0.0, (height - thickness) / 2.0),
        Point(0.0, (height + thickness) / 2.0),
        Point((width - thickness) / 2.0, (height + thickness) / 2.0),
        Point((width - thickness) / 2.0, height),
        Point((width + thickness) / 2.0, height),
        Point((width + thickness) / 2.0, (height + thickness) / 2.0),
        Point(width, (height + thickness) / 2.0),
        Point(width, (height - thickness) / 2.0),
        Point((width + thickness) / 2.0, (height - thickness) / 2.0),
        Point((width + thickness) / 2.0, 0.0)]
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "cross")
  }
}

public struct CircleDescription: Description {
  public static var type: DescriptionType = .circle

  public let radiusRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public let polygonVertexCount: Int
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    radiusRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    polygonVertexCount: Int = 50,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.radiusRange = radiusRange
    self.rotationRange = rotationRange
    self.polygonVertexCount = polygonVertexCount
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let radius = Double.random(in: radiusRange, using: &rng)
    let shape = Circle(
      radiusSegment: Line(Point(0.0, 0.0), Point(radius, 0.0)),
      polygonVertexCount: polygonVertexCount
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "circle")
  }
}

public struct SemiCircleDescription: Description {
  public static var type: DescriptionType = .semiCircle

  public let radiusRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public let polygonVertexCount: Int
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    radiusRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    polygonVertexCount: Int = 50,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.radiusRange = radiusRange
    self.rotationRange = rotationRange
    self.polygonVertexCount = polygonVertexCount
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let radius = Double.random(in: radiusRange, using: &rng)
    let shape = SemiCircle(
      radiusSegment: Line(Point(0.0, 0.0), Point(radius, 0.0)),
      polygonVertexCount: polygonVertexCount
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "semicircle")
  }
}

public struct EllipseDescription: Description {
  public static var type: DescriptionType = .ellipse

  public let horizontalRadiusRange: ClosedRange<Double>
  public let verticalRadiusRange: ClosedRange<Double>
  public let rotationRange: ClosedRange<Double>
  public let polygonVertexCount: Int
  public var allowedColors: [Color]
  public var caption: String?

  public init(
    horizontalRadiusRange: ClosedRange<Double> = 0...1,
    verticalRadiusRange: ClosedRange<Double> = 0...1,
    rotationRange: ClosedRange<Double> = 0...360,
    polygonVertexCount: Int = 50,
    allowedColors: [Color] = Color.allCases,
    caption: String? = nil
  ) {
    self.horizontalRadiusRange = horizontalRadiusRange
    self.verticalRadiusRange = verticalRadiusRange
    self.rotationRange = rotationRange
    self.polygonVertexCount = polygonVertexCount
    self.allowedColors = allowedColors
    self.caption = caption
  }

  public func sampleShape<T: RandomNumberGenerator>(rng: inout T) -> SampledShape {
    let horizontalRadius = Double.random(in: horizontalRadiusRange, using: &rng)
    let verticalRadius = Double.random(in: verticalRadiusRange, using: &rng)
    let shape = Ellipse(
      at: Point(0.0, 0.0),
      horizontalRadius: horizontalRadius,
      verticalRadius: verticalRadius,
      rotationAngle: 0.0,
      polygonVertexCount: polygonVertexCount
    ).rotated(randomlyInRange: rotationRange, rng: &rng)
    return (shape: shape, caption: caption ?? "ellipse")
  }
}
