import Foundation

public typealias BoundingBox = (top: Double, right: Double, bottom: Double, left: Double)
public typealias ColoredShape = (shape: Shape, color: Color, caption: String)

public struct Point {
  public let x: Double
  public let y: Double

  public init(_ x: Double, _ y: Double) {
    self.x = x
    self.y = y
  }
}

public extension Point {
  static func + (left: Point, right: Double) -> Point {
    return Point(left.x + right, left.y + right)
  }

  static func - (left: Point, right: Double) -> Point {
    return Point(left.x - right, left.y - right)
  }

  static func * (left: Point, right: Double) -> Point {
    return Point(left.x * right, left.y * right)
  }

  static func / (left: Point, right: Double) -> Point {
    return Point(left.x / right, left.y / right)
  }

  static func + (left: Point, right: Point) -> Point {
    return Point(left.x + right.x, left.y + right.y)
  }

  static func - (left: Point, right: Point) -> Point {
    return Point(left.x - right.x, left.y - right.y)
  }

  static func * (left: Point, right: Point) -> Point {
    return Point(left.x * right.x, left.y * right.y)
  }

  static func / (left: Point, right: Point) -> Point {
    return Point(left.x / right.x, left.y / right.y)
  }
}

public extension Point {
  /// Checks if this point lies on the left of the provided line.
  internal func isLeft(of line: Line) -> Bool {
    let slope1Term = (line.end.x - line.start.x) * (self.y - line.start.y)
    let slope2Term = (self.x - line.start.x) * (line.end.y - line.start.y)
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
    return Line(left.start + right, left.end + right)
  }

  func intersection(with other: Line) -> Point? {
    let eps = 1e-10

    let a1 = self.end.y - self.start.y
    let b1 = self.start.x - self.end.x
    let c1 = a1 * self.start.x + b1 * self.start.y

    let a2 = other.end.y - other.start.y
    let b2 = other.start.x - other.end.x
    let c2 = a2 * other.start.x + b2 * other.start.y

    // Check if the lines are parallel.
    let det = a1 * b2 - a2 * b1
    if abs(det) < eps {
      return nil
    } else {
      let x = (b2 * c1 - b1 * c2) / det
      let y = (a1 * c2 - a2 * c1) / det
      let xMin1 = min(self.start.x, self.end.x)
      let xMax1 = max(self.start.x, self.end.x)
      let yMin1 = min(self.start.y, self.end.y)
      let yMax1 = max(self.start.y, self.end.y)
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
  func move(by distance: Point) -> Shape
  func scale(by factor: Double) -> Shape
  func rotate(by degrees: Double) -> Shape
  func boundingBox() -> BoundingBox

  func circumscribedConvexPolygon() -> ConvexPolygon
  func svg(color: Color?) -> String
}

public extension Shape {
  func scaleToUnitSize() -> Shape {
    let box = self.boundingBox()
    let maxSize = max(box.top - box.bottom, box.right - box.left)
    return self.scale(by: 1.0 / maxSize)
  }
}

public class SimplePolygon : Shape {
  let vertices: [Point]

  public init(vertices: [Point]) {
    self.vertices = vertices
  }

  public lazy var centroid: Point = {
    [unowned self] in
    var meanX = 0.0
    var meanY = 0.0
    for vertex in self.vertices {
      meanX += vertex.x
      meanY += vertex.y
    }
    meanX /= Double(self.vertices.count)
    meanY /= Double(self.vertices.count)
    return Point(meanX, meanY)
  }()

  public lazy var area: Double = {
    [unowned self] in
    if self.vertices.isEmpty {
      return 0.0
    } else {
      var area = 0.0
      for i in 1..<self.vertices.count {
        area += self.vertices[i-1].x * self.vertices[i].y
        area -= self.vertices[i-1].y * self.vertices[i].x
      }
      area += self.vertices.last!.x * self.vertices[0].y
      area -= self.vertices.last!.y * self.vertices[0].x
      return area / 2.0
    }
  }()

  /// Uses Melkman's convex hull algorithm to obtain the 
  /// convex hull of this polygon.
  public lazy var convexHull: ConvexPolygon = {
    [unowned self] in
    let n = self.vertices.count
    var h = [Point](repeating: Point(0.0, 0.0), count: 2 * n + 1)
    var b = n - 2 // Bottom index of the deque.
    var t = b + 3 // Top index of the deque.

    // Initialize the convex hull using the first three vertices.
    // This forms a counter-clockwise triangle.
    h[b] = self.vertices[2]
    h[t] = self.vertices[2]
    if self.vertices[2].isLeft(of: Line(self.vertices[0], self.vertices[1])) {
      h[b + 1] = self.vertices[0]
      h[b + 2] = self.vertices[1]
    } else {
      h[b + 1] = self.vertices[1]
      h[b + 2] = self.vertices[0]
    }

    // Process the rest of the vertices.
    for i in 3..<n {
      // Test if the current vertex is in the convex hull 
      // and skip it, if it is.
      if self.vertices[i].isLeft(of: Line(h[b], h[b + 1])) && 
         self.vertices[i].isLeft(of: Line(h[t - 1], h[t])) {
        continue
      }

      // Incrementally add an exterior vertex to the convex hull.
      // Get the rightmost vertex in the convex hull.
      while !self.vertices[i].isLeft(of: Line(h[b], h[b + 1])) {
        b += 1
      }
      b -= 1
      h[b] = self.vertices[i] // Insert the current vertex at the bottom of the queue.

      // Get the leftmost vertex in the convex hull.
      while !self.vertices[i].isLeft(of: Line(h[t - 1], h[t])) {
        t -= 1
      }
      t += 1
      h[t] = self.vertices[i] // Insert the current vertex at the top of the queue.
    }

    return ConvexPolygon(vertices: Array(h[b...t]))
  }()

  /// Checks whether the provided point is in this polygon.
  /// Based on: https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html
  public func contains(_ point: Point) -> Bool {
    let n = self.vertices.count
    var j = n - 1
    var result = false
    for i in 0..<n {
      if (self.vertices[i].y > point.y) != (self.vertices[j].y > point.y) &&
         (point.x < (self.vertices[j].x - self.vertices[i].x) * 
                    (point.y - self.vertices[i].y) / 
                    (self.vertices[j].y - self.vertices[i].y) + 
                    self.vertices[i].x) {
        result = !result
      }
      j = i
    }
    return result
  }

  public func move(by distance: Point) -> Shape {
    return SimplePolygon(vertices: vertices.map { $0 + distance })
  }

  public func scale(by factor: Double) -> Shape {
    let centroid = self.centroid
    return SimplePolygon(vertices: vertices.map {
      let centered = $0 - centroid
      let scaled = centered * factor
      return scaled + centroid
    })
  }

  public func rotate(by degrees: Double) -> Shape {
    let centroid = self.centroid
    let cosD = __cospi(degrees / 180.0)
    let sinD = __sinpi(degrees / 180.0)
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
      top: self.vertices[0].y, 
      right: self.vertices[0].x, 
      bottom: self.vertices[0].y, 
      left: self.vertices[0].x)
    for vertex in self.vertices {
      box = (
        top: min(vertex.y, box.top), 
        right: max(vertex.x, box.right), 
        bottom: max(vertex.y, box.bottom), 
        left: min(vertex.x, box.left))
    }
    return box
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    return convexHull
  }

  public func svg(color: Color?) -> String {
    let n = self.vertices.count
    var svgPath = ""
    for i in 0..<n {
      if i == 0 {
        svgPath += "M \(self.vertices[i].x) \(self.vertices[i].y) "
      } else {
        svgPath += "L \(self.vertices[i].x) \(self.vertices[i].y) "
      }
    }
    svgPath += "L \(self.vertices[0].x) \(self.vertices[0].y)"
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return "<path d=\"\(svgPath)\" \(color) />"
  }
}

public class ConvexPolygon : SimplePolygon {
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
    let n = self.vertices.count
    var intersectionPoints = [Point]()
    for i in 0..<n {
      let next = i + 1 == n ? 0 : i + 1
      if let point = line.intersection(with: Line(self.vertices[i], self.vertices[next])) {
        intersectionPoints.append(point)
      }
    }
    return intersectionPoints
  }

  /// Returns the intersection of this polygon with `other`, which is also a convex polygon.
  public func intersection(with other: ConvexPolygon) -> ConvexPolygon {
    var clippedVertices = [Point]()

    // Add the vertices of this polygon that are inside `other`.
    for vertex in self.vertices {
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
    let n = self.vertices.count
    for i in 0..<n {
      let next = i + 1 == n ? 0 : i + 1
      let points = other.intersection(with: Line(self.vertices[i], self.vertices[next]))
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

public class Circle : Shape {
  let radiusSegment: Line
  let polygonNumVertices: Int

  public lazy var origin: Point = {
    [unowned self] in
    return self.radiusSegment.start
  }()

  public lazy var radius: Double = {
    [unowned self] in
    let difference = self.radiusSegment.end - self.radiusSegment.start
    return sqrt(difference.x * difference.x + difference.y * difference.y)
  }()

  internal lazy var approximateConvexHull: ConvexPolygon = {
    [unowned self] in
    let n = self.polygonNumVertices
    let a = 2 * Double.pi / Double(n)
    let r = self.radius / cos(a / 2)
    var vertices = [Point]()
    vertices.reserveCapacity(n)
    var theta = 0.0
    for _ in 0..<n {
      let x = self.origin.x + r * cos(theta)
      let y = self.origin.y + r * sin(theta)
      vertices.append(Point(x, y))
      theta -= a
    }
    return ConvexPolygon(vertices: vertices)
  }()

  public init(radiusSegment: Line, polygonNumVertices: Int = 100) {
    self.radiusSegment = radiusSegment
    self.polygonNumVertices = polygonNumVertices
  }

  public func move(by distance: Point) -> Shape {
    return Circle(
      radiusSegment: self.radiusSegment + distance,
      polygonNumVertices: polygonNumVertices)
  }

  public func scale(by factor: Double) -> Shape {
    let start = self.radiusSegment.start
    let end = start + (self.radiusSegment.end - start) * factor
    return Circle(
      radiusSegment: Line(start, end),
      polygonNumVertices: polygonNumVertices)
  }

  public func rotate(by degrees: Double) -> Shape {
    return self
  }

  public func boundingBox() -> BoundingBox {
    return approximateConvexHull.boundingBox()
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    return approximateConvexHull
  }

  public func svg(color: Color?) -> String {
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return """
      <circle 
        cx="\(self.origin.x)" 
        cy="\(self.origin.y)" 
        r="\(self.radius)" 
        \(color) />
      """
  }
}

public class SemiCircle : Shape {
  let radiusSegment: Line
  let polygonNumVertices: Int

  public lazy var origin: Point = {
    [unowned self] in
    return self.radiusSegment.start
  }()

  public lazy var radius: Double = {
    [unowned self] in
    let difference = self.radiusSegment.end - self.radiusSegment.start
    return sqrt(difference.x * difference.x + difference.y * difference.y)
  }()

  internal lazy var approximateConvexHull: ConvexPolygon = {
    [unowned self] in
    let n = self.polygonNumVertices / 2
    let a = Double.pi / Double(n)
    let r = self.radius / cos(a)
    var vertices = [Point]()
    vertices.reserveCapacity(n)
    let difference = self.radiusSegment.end - self.radiusSegment.start
    var theta = atan2(difference.y, difference.x) - Double.pi
    for _ in 0...n {
      let x = self.origin.x + r * cos(theta)
      let y = self.origin.y + r * sin(theta)
      vertices.append(Point(x, y))
      theta += a
    }
    return ConvexPolygon(vertices: vertices)
  }()

  public init(radiusSegment: Line, polygonNumVertices: Int = 100) {
    self.radiusSegment = radiusSegment
    self.polygonNumVertices = polygonNumVertices
  }

  public func move(by distance: Point) -> Shape {
    return SemiCircle(
      radiusSegment: self.radiusSegment + distance,
      polygonNumVertices: polygonNumVertices)
  }

  public func scale(by factor: Double) -> Shape {
    let start = self.radiusSegment.start
    let end = start + (self.radiusSegment.end - start) * factor
    return SemiCircle(
      radiusSegment: Line(start, end),
      polygonNumVertices: polygonNumVertices)
  }

  public func rotate(by degrees: Double) -> Shape {
    let cosD = __cospi(degrees / 180.0)
    let sinD = __sinpi(degrees / 180.0)
    let start = self.radiusSegment.start
    let end = self.radiusSegment.end
    let centeredEnd = end - start
    let rotatedEnd = Point(
        cosD * centeredEnd.x - sinD * centeredEnd.y,
        sinD * centeredEnd.x + cosD * centeredEnd.y)
    return SemiCircle(
      radiusSegment: Line(start, start + rotatedEnd),
      polygonNumVertices: polygonNumVertices)
  }

  public func boundingBox() -> BoundingBox {
    return approximateConvexHull.boundingBox()
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    return approximateConvexHull
  }

  public func svg(color: Color?) -> String {
    let end = self.radiusSegment.end
    let start = self.radiusSegment.start * 2 - end
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return """
      <path 
        d="M\(start.x),\(start.y) A1,1 0 0,1 \(end.x),\(end.y)"
        \(color) />
      """
  }
}

public class Ellipse : Shape {
  let origin: Point
  let horizontalRadius: Double
  let verticalRadius: Double
  let rotationAngle: Double
  let polygonNumVertices: Int

  internal lazy var approximateConvexHull: ConvexPolygon = {
    [unowned self] in
    // For this we are generating a polygon approximation to a circle based on 
    // horizontal radius, then scaling it along the y-axis by the appropriate 
    // ratio, and finally rotating it.
    let cosRotationAngle = __cospi(self.rotationAngle / 180.0)
    let sinRotationAngle = __sinpi(self.rotationAngle / 180.0)
    let n = self.polygonNumVertices
    let a = 2 * Double.pi / Double(n)
    let r = self.horizontalRadius / cos(a / 2)
    var vertices = [Point]()
    vertices.reserveCapacity(n)
    var theta = 0.0
    for _ in 0..<n {
      let centeredX = r * cos(theta)
      let centeredY = r * sin(theta)
      let scaledY = centeredY * self.verticalRadius / self.horizontalRadius
      let x = self.origin.x + centeredX * cosRotationAngle - scaledY * sinRotationAngle
      let y = self.origin.y + centeredX * sinRotationAngle + scaledY * cosRotationAngle
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
    polygonNumVertices: Int = 100
  ) {
    self.origin = origin
    self.horizontalRadius = horizontalRadius
    self.verticalRadius = verticalRadius
    self.rotationAngle = rotationAngle
    self.polygonNumVertices = polygonNumVertices
  }

  public func move(by distance: Point) -> Shape {
    return Ellipse(
      at: self.origin + distance,
      horizontalRadius: self.horizontalRadius,
      verticalRadius: self.verticalRadius,
      rotationAngle: self.rotationAngle,
      polygonNumVertices: polygonNumVertices)
  }

  public func scale(by factor: Double) -> Shape {
    return Ellipse(
      at: self.origin,
      horizontalRadius: self.horizontalRadius * factor,
      verticalRadius: self.verticalRadius * factor,
      rotationAngle: self.rotationAngle,
      polygonNumVertices: polygonNumVertices)
  }

  public func rotate(by degrees: Double) -> Shape {
    return Ellipse(
      at: self.origin,
      horizontalRadius: self.horizontalRadius,
      verticalRadius: self.verticalRadius,
      rotationAngle: self.rotationAngle + degrees,
      polygonNumVertices: polygonNumVertices)
  }

  public func boundingBox() -> BoundingBox {
    return approximateConvexHull.boundingBox()
  }

  public func circumscribedConvexPolygon() -> ConvexPolygon {
    return approximateConvexHull
  }

  public func svg(color: Color?) -> String {
    let color = color.map { "fill=\"\($0.rawValue)\"" } ?? ""
    return """
      <ellipse 
        cx="\(self.origin.x)" 
        cy="\(self.origin.y)" 
        rx="\(self.horizontalRadius)" 
        ry="\(self.verticalRadius)"
        transform="rotate(\(self.rotationAngle), \(self.origin.x), \(self.origin.y))"
        \(color) />
      """
  }
}
