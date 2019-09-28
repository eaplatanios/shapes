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

import SPMUtility

extension Double: ArgumentKind {
  public init(argument: String) throws {
    guard let double = Double(argument) else {
      throw ArgumentConversionError.typeMismatch(value: argument, expectedType: Double.self)
    }
    self = double
  }

  public static let completion: ShellCompletion = .none
}

// Helper for properly decoding description types when used as dictionary keys.
extension KeyedDecodingContainer {
  public func decode(
    _ type: [DescriptionType: AnyDescription].Type,
    forKey key: Key
  ) throws -> [DescriptionType: AnyDescription] {
    let stringDictionary = try self.decode([String: AnyDescription].self, forKey: key)
    var dictionary = [DescriptionType: AnyDescription]()
    for (key, value) in stringDictionary {
      guard let descriptionType = DescriptionType(rawValue: key) else {
        let context = DecodingError.Context(
          codingPath: codingPath,
          debugDescription: "Could not parse json key to a 'DescriptionType' value.")
        throw DecodingError.dataCorrupted(context)
      }
      dictionary[descriptionType] = value
    }
    return dictionary
  }
}
