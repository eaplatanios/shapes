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

public typealias BoundingBox = (top: Double, right: Double, bottom: Double, left: Double)

public struct Point {
  public let x: Double
  public let y: Double

  public init(_ x: Double, _ y: Double) {
    self.x = x
    self.y = y
  }
}

extension Point {
  public static func + (left: Point, right: Double) -> Point {
    Point(left.x + right, left.y + right)
  }

  public static func - (left: Point, right: Double) -> Point {
    Point(left.x - right, left.y - right)
  }

  public static func * (left: Point, right: Double) -> Point {
    Point(left.x * right, left.y * right)
  }

  public static func / (left: Point, right: Double) -> Point {
    Point(left.x / right, left.y / right)
  }

  public static func + (left: Point, right: Point) -> Point {
    Point(left.x + right.x, left.y + right.y)
  }

  public static func - (left: Point, right: Point) -> Point {
    Point(left.x - right.x, left.y - right.y)
  }

  public static func * (left: Point, right: Point) -> Point {
    Point(left.x * right.x, left.y * right.y)
  }

  public static func / (left: Point, right: Point) -> Point {
    Point(left.x / right.x, left.y / right.y)
  }
}

public extension Point {
  /// Checks if this point lies on the left of the provided line.
  internal func isLeft(of line: Line) -> Bool {
    let slope1Term = (line.end.x - line.start.x) * (y - line.start.y)
    let slope2Term = (x - line.start.x) * (line.end.y - line.start.y)
    return slope1Term - slope2Term > 0
  }
}

public struct Line {
  let start: Point
  let end: Point

  public init(_ start: Point, _ end: Point) {
    self.start = start
    self.end = end
  }
}

public extension Line {
  static func + (left: Line, right: Point) -> Line {
    Line(left.start + right, left.end + right)
  }

  func intersection(with other: Line) -> Point? {
    let eps = 1e-10

    let a1 = end.y - start.y
    let b1 = start.x - end.x
    let c1 = a1 * start.x + b1 * start.y

    let a2 = other.end.y - other.start.y
    let b2 = other.start.x - other.end.x
    let c2 = a2 * other.start.x + b2 * other.start.y

    // Check if the two lines are parallel.
    let det = a1 * b2 - a2 * b1
    if abs(det) < eps {
      return nil
    } else {
      let x = (b2 * c1 - b1 * c2) / det
      let y = (a1 * c2 - a2 * c1) / det
      let xMin1 = min(start.x, end.x)
      let xMax1 = max(start.x, end.x)
      let yMin1 = min(start.y, end.y)
      let yMax1 = max(start.y, end.y)
      let isOnLine1 = (xMin1 < x || abs(xMin1 - x) < eps) &&
                      (xMax1 > x || abs(xMax1 - x) < eps) &&
                      (yMin1 < y || abs(yMin1 - y) < eps) &&
                      (yMax1 > y || abs(yMax1 - y) < eps)
      let xMin2 = min(other.start.x, other.end.x)
      let xMax2 = max(other.start.x, other.end.x)
      let yMin2 = min(other.start.y, other.end.y)
      let yMax2 = max(other.start.y, other.end.y)
      let isOnLine2 = (xMin2 < x || abs(xMin2 - x) < eps) &&
                      (xMax2 > x || abs(xMax2 - x) < eps) &&
                      (yMin2 < y || abs(yMin2 - y) < eps) &&
                      (yMax2 > y || abs(yMax2 - y) < eps)
      
      if isOnLine1 && isOnLine2 {
        return Point(x, y)
      } else {
        // The intersection point is outside both line segments.
        return nil
      }
    }
  }
}

public protocol Shape {
  func moved(by distance: Point) -> Shape
  func scaled(by factor: Double) -> Shape
  func rotated(by degrees: Double) -> Shape
  func boundingBox() -> BoundingBox
  func circumscribedConvexPolygon() -> ConvexPolygon
  func svg(color: Color?) -> String
}

extension Shape {
  public func scaledToUnitSize() -> Shape {
    let box = boundingBox()
    let maxSize = max(box.top - box.bottom, box.right - box.left)
    return scaled(by: 1.0 / maxSize)
  }

  public func rotated<T: RandomNumberGenerator>(
    randomlyInRange range: ClosedRange<Double>,
    rng: inout T
  ) -> Shape {
    rotated(by: Double.random(in: range, using: &rng))
  }

  public func positioned<T: RandomNumberGenerator>(
    randomlyInBox box: (width: Double, height: Double),
    rng: inout T
  ) -> Shape? {
    let boundingBox = self.boundingBox()
    let width = boundingBox.right - boundingBox.left
    let height = boundingBox.bottom - boundingBox.top
    let minX = -boundingBox.left
    let minY = -boundingBox.top
    let maxX = abs(box.width - boundingBox.right)
    let maxY = abs(box.height - boundingBox.bottom)
    if box.width < width || box.height < height { return nil }
    let p = Point(
      Double.random(in: minX...maxX, using: &rng),
      Double.random(in: minY...maxY, using: &rng))
    return moved(by: p)
  }
}

public class SimplePolygon: Shape {
  public let vertices: [Point]

  public init(vertices: [Point]) {
    self.vertices = vertices
  }

  public lazy var centroid: Point = {
    var meanX = 0.0
    var meanY = 0.0
    for vertex in vertices {
      meanX += vertex.x
      meanY += vertex.y
    }
    meanX /= Double(vertices.count)
    meanY /= Double(vertices.count)
    return Point(meanX, meanY)
  }()

  public lazy var area: Double = {
    if vertices.isEmpty {
      return 0.0
    } else {
      var area = 0.0
      for i in 1..<vertices.count {
        area += vertices[i-1].x * vertices[i].y
        area -= vertices[i-1].y * vertices[i].x
      }
      area += vertices.last!.x * vertices[0].y
      area -= vertices.last!.y * vertices[0].x
      return area / 2.0
    }
  }()

  /// Uses Melkman's convex hull algorithm to obtain the 
  /// convex hull of this polygon.
  public lazy var convexHull: ConvexPolygon = {
    let n = vertices.count
    var h = [Point](repeating: Point(0.0, 0.0), count: 2 * n + 1)
    var b = n - 2 // Bottom index of the deque.
    var t = b + 3 // Top index of the deque.

    // Initialize the convex hull using the first three vertices.
    // This forms a counter-clockwise triangle.
    h[b] = vertices[2]
    h[t] = vertices[2]
    if vertices[2].isLeft(of: Line(vertices[0], vertices[1])) {
      h[b + 1] = vertices[0]
      h[b + 2] = vertices[1]
    } else {
      h[b + 1] = vertices[1]
      h[b + 2] = vertices[0]
    }

    // Process the rest of the vertices.
    for i in 3..<n {
      // Test if the current vertex is in the convex hull 
      // and skip it, if it is.
      if vertices[i].isLeft(of: Line(h[b], h[b + 1])) &&
         vertices[i].isLeft(of: Line(h[t - 1], h[t])) {
        continue
      }

      // Incrementally add an exterior vertex to the convex hull.
      // Get the rightmost vertex in the convex hull.
      while !vertices[i].isLeft(of: Line(h[b], h[b + 1])) { b += 1 }
      b -= 1
      h[b] = vertices[i] // Insert the current vertex at the bottom of the queue.

      // Get the leftmost vertex in the convex hull.
      while !vertices[i].isLeft(of: Line(h[t - 1], h[t])) { t -= 1 }
      t += 1
      h[t] = vertices[i] // Insert the current vertex at the top of the queue.
    }

    return ConvexPolygon(vertices: Array(h[b...t]))
  }()

  /// Checks whether the provided point is in this polygon.
  /// Based on: https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html
  public func contains(_ point: Point) -> Bool {
    let n = vertices.count
    var j = n - 1
    var result = false
    for i in 0..<n {
      if (vertices[i].y > point.y) != (vertices[j].y > point.y) &&
         (point.x < (vertices[j].x - vertices[i].x) *
                    (point.y - vertices[i].y) /
                    (vertices[j].y - vertices[i].y) +
                    vertices[i].x) {
        result = !result
      }
      j = i
    }
    return result
  }

  public func moved(by distance: Point) -> Shape {
    SimplePolygon(vertices: vertices.map { $0 + distance })
  }

  public func scaled(by factor: Double) -> Shape {
    SimplePolygon(vertices: vertices.map {
      let centered = $0 - centroid
      let scaled = centered * factor
      return scaled + centroid
    })
  }

  public func rotated(by degrees: Double) -> Shape {
    let cosD = cos(Double.pi * degrees / 180.0)
    let sinD = sin(Double.pi * degrees / 180.0)
    return SimplePolygon(vertices: vertices.map {
      let centered = $0 - centroid
      let rotated = Point(
        cosD * centered.x - sinD * centered.y,
        sinD * centered.x + cosD * centered.y)
      return rotated + centroid
    })
  }

  public func boundingBox() -> BoundingBox {
    var box = (
      top: vertices[0].y,
      right: vertices[0].x,
      bottom: vertices[0].y,
      left: vertices[0].x)
    for vertex in vertices {
      box = (
        top: min(vertex.y, box.top),
        right: max(vertex.x, box.right),
        bottom: max(vertex.y, box.bottom),
        left: min(vertex.x, box.left))
    }
    return box
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    convexHull
  }

  public func svg(color: Color?) -> String {
    let n = vertices.count
    var svgPath = ""
    for i in 0..<n {
      if i == 0 {
        svgPath += "M \(vertices[i].x) \(vertices[i].y) "
      } else {
        svgPath += "L \(vertices[i].x) \(vertices[i].y) "
      }
    }
    svgPath += "L \(vertices[0].x) \(vertices[0].y)"
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return "<path d=\"\(svgPath)\" \(color) />"
  }
}

public class ConvexPolygon: SimplePolygon {
  public override init(vertices: [Point]) {
    var meanX = 0.0
    var meanY = 0.0
    for vertex in vertices {
      meanX += vertex.x
      meanY += vertex.y
    }
    meanX /= Double(vertices.count)
    meanY /= Double(vertices.count)

    let sortedVertices = vertices.sorted(by: {
      atan2($0.y - meanY, $0.x - meanX) < atan2($1.y - meanY, $1.x - meanX)
    })

    super.init(vertices: sortedVertices)
  }

  /// Computes all intersection points of this polygon with the provided line.
  public func intersection(with line: Line) -> [Point] {
    let n = vertices.count
    var intersectionPoints = [Point]()
    for i in 0..<n {
      let next = i + 1 == n ? 0 : i + 1
      if let point = line.intersection(with: Line(vertices[i], vertices[next])) {
        intersectionPoints.append(point)
      }
    }
    return intersectionPoints
  }

  /// Returns the intersection of this polygon with `other`, which is also a convex polygon.
  public func intersection(with other: ConvexPolygon) -> ConvexPolygon {
    var clippedVertices = [Point]()

    // Add the vertices of this polygon that are inside `other`.
    for vertex in vertices {
      if other.contains(vertex){
        clippedVertices.append(vertex)
      }
    }

    // Add the vertices of `other` that are inside this polygon.
    for vertex in other.vertices {
      if self.contains(vertex) {
        clippedVertices.append(vertex)
      }
    }

    // Add the intersection points.
    let n = vertices.count
    for i in 0..<n {
      let next = i + 1 == n ? 0 : i + 1
      let points = other.intersection(with: Line(vertices[i], vertices[next]))
      clippedVertices.append(contentsOf: points)
    }

    return ConvexPolygon(vertices: clippedVertices)
  }

  public func intersectionRatio(with other: ConvexPolygon) -> Double {
    let area1 = self.area
    let area2 = other.area
    let intersectionArea = self.intersection(with: other).area
    return max(intersectionArea / area1, intersectionArea / area2)
  }
}

public class Circle: Shape {
  public let radiusSegment: Line
  public let polygonVertexCount: Int

  public lazy var origin: Point = radiusSegment.start

  public lazy var radius: Double = {
    let difference = radiusSegment.end - radiusSegment.start
    return sqrt(difference.x * difference.x + difference.y * difference.y)
  }()

  internal lazy var approximateConvexHull: ConvexPolygon = {
    let a = 2 * Double.pi / Double(polygonVertexCount)
    let r = radius / cos(a / 2)
    var vertices = [Point]()
    vertices.reserveCapacity(polygonVertexCount)
    var theta = 0.0
    for _ in 0..<polygonVertexCount {
      let x = origin.x + r * cos(theta)
      let y = origin.y + r * sin(theta)
      vertices.append(Point(x, y))
      theta -= a
    }
    return ConvexPolygon(vertices: vertices)
  }()

  public init(radiusSegment: Line, polygonVertexCount: Int = 100) {
    self.radiusSegment = radiusSegment
    self.polygonVertexCount = polygonVertexCount
  }

  public func moved(by distance: Point) -> Shape {
    Circle(
      radiusSegment: radiusSegment + distance,
      polygonVertexCount: polygonVertexCount)
  }

  public func scaled(by factor: Double) -> Shape {
    let start = radiusSegment.start
    let end = start + (radiusSegment.end - start) * factor
    return Circle(
      radiusSegment: Line(start, end),
      polygonVertexCount: polygonVertexCount)
  }

  public func rotated(by degrees: Double) -> Shape {
    self
  }

  public func boundingBox() -> BoundingBox {
    approximateConvexHull.boundingBox()
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    approximateConvexHull
  }

  public func svg(color: Color?) -> String {
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return """
      <circle 
        cx="\(origin.x)" 
        cy="\(origin.y)" 
        r="\(radius)" 
        \(color) />
      """
  }
}

public class SemiCircle: Shape {
  public let radiusSegment: Line
  public let polygonVertexCount: Int

  public lazy var origin: Point = radiusSegment.start

  public lazy var radius: Double = {
    let difference = radiusSegment.end - radiusSegment.start
    return sqrt(difference.x * difference.x + difference.y * difference.y)
  }()

  internal lazy var approximateConvexHull: ConvexPolygon = {
    let n = polygonVertexCount / 2
    let a = Double.pi / Double(n)
    let r = radius / cos(a)
    var vertices = [Point]()
    vertices.reserveCapacity(n)
    let difference = radiusSegment.end - radiusSegment.start
    var theta = atan2(difference.y, difference.x) - Double.pi
    for _ in 0...n {
      let x = origin.x + r * cos(theta)
      let y = origin.y + r * sin(theta)
      vertices.append(Point(x, y))
      theta += a
    }
    return ConvexPolygon(vertices: vertices)
  }()

  public init(radiusSegment: Line, polygonVertexCount: Int = 100) {
    self.radiusSegment = radiusSegment
    self.polygonVertexCount = polygonVertexCount
  }

  public func moved(by distance: Point) -> Shape {
    SemiCircle(
      radiusSegment: radiusSegment + distance,
      polygonVertexCount: polygonVertexCount)
  }

  public func scaled(by factor: Double) -> Shape {
    let start = radiusSegment.start
    let end = start + (radiusSegment.end - start) * factor
    return SemiCircle(
      radiusSegment: Line(start, end),
      polygonVertexCount: polygonVertexCount)
  }

  public func rotated(by degrees: Double) -> Shape {
    let cosD = cos(Double.pi * degrees / 180.0)
    let sinD = sin(Double.pi * degrees / 180.0)
    let start = radiusSegment.start
    let end = radiusSegment.end
    let centeredEnd = end - start
    let rotatedEnd = Point(
      cosD * centeredEnd.x - sinD * centeredEnd.y,
      sinD * centeredEnd.x + cosD * centeredEnd.y)
    return SemiCircle(
      radiusSegment: Line(start, start + rotatedEnd),
      polygonVertexCount: polygonVertexCount)
  }

  public func boundingBox() -> BoundingBox {
    approximateConvexHull.boundingBox()
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    approximateConvexHull
  }

  public func svg(color: Color?) -> String {
    let end = radiusSegment.end
    let start = radiusSegment.start * 2 - end
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return """
      <path 
        d="M\(start.x),\(start.y) A1,1 0 0,1 \(end.x),\(end.y)"
        \(color) />
      """
  }
}

public class Ellipse: Shape {
  public let origin: Point
  public let horizontalRadius: Double
  public let verticalRadius: Double
  public let rotationAngle: Double
  public let polygonVertexCount: Int

  internal lazy var approximateConvexHull: ConvexPolygon = {
    // For this we are generating a polygon approximation to a circle based on 
    // horizontal radius, then scaling it along the y-axis by the appropriate 
    // ratio, and finally rotating it.
    let cosRotationAngle = cos(Double.pi * rotationAngle / 180.0)
    let sinRotationAngle = sin(Double.pi * rotationAngle / 180.0)
    let a = 2 * Double.pi / Double(polygonVertexCount)
    let r = horizontalRadius / cos(a / 2)
    var vertices = [Point]()
    vertices.reserveCapacity(polygonVertexCount)
    var theta = 0.0
    for _ in 0..<polygonVertexCount {
      let centeredX = r * cos(theta)
      let centeredY = r * sin(theta)
      let scaledY = centeredY * verticalRadius / horizontalRadius
      let x = origin.x + centeredX * cosRotationAngle - scaledY * sinRotationAngle
      let y = origin.y + centeredX * sinRotationAngle + scaledY * cosRotationAngle
      vertices.append(Point(x, y))
      theta -= a
    }
    return ConvexPolygon(vertices: vertices)
  }()

  public init(
    at origin: Point,
    horizontalRadius: Double,
    verticalRadius: Double,
    rotationAngle: Double,
    polygonVertexCount: Int = 100
  ) {
    self.origin = origin
    self.horizontalRadius = horizontalRadius
    self.verticalRadius = verticalRadius
    self.rotationAngle = rotationAngle
    self.polygonVertexCount = polygonVertexCount
  }

  public func moved(by distance: Point) -> Shape {
    Ellipse(
      at: origin + distance,
      horizontalRadius: horizontalRadius,
      verticalRadius: verticalRadius,
      rotationAngle: rotationAngle,
      polygonVertexCount: polygonVertexCount)
  }

  public func scaled(by factor: Double) -> Shape {
    Ellipse(
      at: origin,
      horizontalRadius: horizontalRadius * factor,
      verticalRadius: verticalRadius * factor,
      rotationAngle: rotationAngle,
      polygonVertexCount: polygonVertexCount)
  }

  public func rotated(by degrees: Double) -> Shape {
    Ellipse(
      at: origin,
      horizontalRadius: horizontalRadius,
      verticalRadius: verticalRadius,
      rotationAngle: rotationAngle + degrees,
      polygonVertexCount: polygonVertexCount)
  }

  public func boundingBox() -> BoundingBox {
    approximateConvexHull.boundingBox()
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    approximateConvexHull
  }

  public func svg(color: Color?) -> String {
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return """
      <ellipse 
        cx="\(origin.x)" 
        cy="\(origin.y)" 
        rx="\(horizontalRadius)" 
        ry="\(verticalRadius)"
        transform="rotate(\(rotationAngle), \(origin.x), \(origin.y))"
        \(color) />
      """
  }
}
