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

public typealias GeneratedImage = (svg: String, caption: String)

public struct Configuration: Codable {
  let width: Double
  let height: Double
  let backgroundColor: Color
  let imageCountPerDescription: Int
  let shuffledDescriptions: Bool
  let maxOverlapRatio: Double
  let randomShapeCountRange: ClosedRange<Int>
  let allowedRandomDescriptions: [AnyDescription]
  let captionDescriptions: [DescriptionType: AnyDescription]

  public static func from(json: String) throws -> Configuration {
    try JSONDecoder().decode(Configuration.self, from: json.data(using: .utf8)!)
  }
}

public extension Configuration {
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
    for descriptions: [Description],
    configuration: Configuration
  ) -> GeneratedImage {
    var shuffledDescriptions = [Description]()
    let randomImageCount = Int.random(in: configuration.randomShapeCountRange, using: &rng)
    for _ in 0..<randomImageCount {
      let randomDescription = configuration.allowedRandomDescriptions.randomElement(using: &rng)!
      shuffledDescriptions.append(randomDescription.base)
    }
    shuffledDescriptions.append(
      contentsOf: configuration.shuffledDescriptions ? descriptions.shuffled() : descriptions)
    var shapes = [SampledColoredShape]()
    var i = 0
    while i < shuffledDescriptions.count {
      let (shape, color, caption) = shuffledDescriptions[i].sampleColoredShape(rng: &rng)
      let positionedShape = shape.positioned(
        randomlyInBox: (width: configuration.width, height: configuration.height),
        rng: &rng)
      if (positionedShape == nil || !checkShape(
        shape: positionedShape!,
        sampledShapes: shapes,
        maxOverlapRatio: configuration.maxOverlapRatio)) {
        shapes.removeAll()
        i = 0
      } else {
        shapes.append((positionedShape!, color, caption))
        i += 1
      }
    }
    let svg = """
      <svg 
        xmlns="http://www.w3.org/2000/svg"
        width="\(configuration.width)" 
        height="\(configuration.height)" 
        viewBox="0 0 \(configuration.width) \(configuration.height)" 
        style="background-color: \(configuration.backgroundColor.rawValue)">
        \(shapes.map { $0.shape.svg(color: $0.color) } .joined())
      </svg>
      """
    let caption = shapes.map { $0.caption } .joined(separator: ", ")
    return (svg: svg, caption: caption)
  }

  internal func checkShape(
    shape: Shape,
    sampledShapes: [SampledColoredShape],
    maxOverlapRatio: Double? = nil
  ) -> Bool {
    if let maxOverlap = maxOverlapRatio {
      let shapeBB = shape.circumscribedConvexPolygon()
      for existingShape in sampledShapes {
        let overlapRatio = shapeBB.intersectionRatio(
          with: existingShape.shape.circumscribedConvexPolygon())
        if overlapRatio > maxOverlap {
          return false
        }
      }
    }
    return true
  }
}
