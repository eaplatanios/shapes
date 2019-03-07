import Foundation

public func parseCaptions(_ string: String) throws -> [Caption] {
  let components = string.components(separatedBy: "\n")
  return try components.map { try parseCaption($0) }
}

/// Parses a single set of colored shape descriptions.
/// The expected format for the provided string is a comma-separate list 
/// of either a single shape, or a color and a shape. For example:
/// ```
/// red triangle, blue circle, square, yellow shape
/// ```
public func parseCaption(_ string: String) throws -> Caption {
  let components = string.components(separatedBy: ",")
  return try components.map { try parseDescription($0) }
}

internal func parseDescription(_ string: String) throws -> Description {
  let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
  let parts = trimmed.components(separatedBy: " ").map { 
    $0.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  let color = parts.count > 1 ? Color(rawValue: parts[0]) : nil
  let shape = parts.count > 1 ? parts[1] : parts[0]
  switch shape {
  case "triangle": return TriangleDescription(color: color)
  case "square": return SquareDescription(color: color)
  case "rectangle": return RectangleDescription(color: color)
  case "pentagon": return PentagonDescription(color: color)
  case "cross": return CrossDescription(color: color)
  case "circle": return CircleDescription(color: color)
  case "semicircle": return SemiCircleDescription(color: color)
  case "ellipse": return EllipseDescription(color: color)
  default: throw DataError.invalidShape(shape)
  }
}
