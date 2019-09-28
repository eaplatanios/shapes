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

public func parseCaptions(
  _ string: String,
  for configuration: Configuration
) throws -> [[Description]] {
  try string.components(separatedBy: "\n")
    .filter { $0.count > 0 }
    .map { try parseCaption($0, for: configuration) }
}

/// Parses a single set of colored shape descriptions.
/// The expected format for the provided string is a comma-separate list 
/// of either a single shape, or a color and a shape. For example:
/// ```
/// red triangle, blue circle, square, yellow shape
/// ```
public func parseCaption(
  _ string: String,
  for configuration: Configuration
) throws -> [Description] {
  try string.components(separatedBy: ",").map {
    try parseDescription($0, for: configuration)
  }
}

internal func parseDescription(
  _ string: String,
  for configuration: Configuration
) throws -> Description {
  let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
  let parts = trimmed.components(separatedBy: " ").map {
    $0.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  let color = parts.count > 1 ? Color(rawValue: parts[0]) : nil
  let shape = parts.count > 1 ? parts[1] : parts[0]
  var description = try { () -> Description in
    switch shape {
    case "triangle": return configuration.captionDescriptions[.triangle]!.base
    case "square": return configuration.captionDescriptions[.square]!.base
    case "rectangle": return configuration.captionDescriptions[.rectangle]!.base
    case "pentagon": return configuration.captionDescriptions[.pentagon]!.base
    case "regularPolygon": return configuration.captionDescriptions[.regularPolygon]!.base
    case "cross": return configuration.captionDescriptions[.cross]!.base
    case "circle": return configuration.captionDescriptions[.circle]!.base
    case "semiCircle": return configuration.captionDescriptions[.semiCircle]!.base
    case "ellipse": return configuration.captionDescriptions[.ellipse]!.base
    default: throw DataError.invalidShape(shape)
    }
  }()
  description.caption = string
  if let c = color {
    description.allowedColors = [c]
  }
  return description
}
