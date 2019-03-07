import Utility

extension Double: ArgumentKind {
  public init(argument: String) throws {
    guard let double = Double(argument) else {
      throw ArgumentConversionError.typeMismatch(value: argument, expectedType: Double.self)
    }

    self = double
  }

  public static let completion: ShellCompletion = .none
}

extension ClosedRange: Decodable where Bound: Decodable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let lowerBound = try container.decode(Bound.self)
    let upperBound = try container.decode(Bound.self)
    guard lowerBound <= upperBound else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Cannot initialize \(ClosedRange.self) with a lowerBound (\(lowerBound)) greater than upperBound (\(upperBound))"))
    }
    self.init(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }
}

extension ClosedRange: Encodable where Bound: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(self.lowerBound)
    try container.encode(self.upperBound)
  }
}

extension Range: Decodable where Bound: Decodable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let lowerBound = try container.decode(Bound.self)
    let upperBound = try container.decode(Bound.self)
    guard lowerBound <= upperBound else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Cannot initialize \(Range.self) with a lowerBound (\(lowerBound)) greater than upperBound (\(upperBound))"))
    }
    self.init(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }
}

extension Range: Encodable where Bound: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(self.lowerBound)
    try container.encode(self.upperBound)
  }
}

extension PartialRangeUpTo: Decodable where Bound: Decodable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    try self.init(container.decode(Bound.self))
  }
}

extension PartialRangeUpTo: Encodable where Bound: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(self.upperBound)
  }
}

extension PartialRangeThrough: Decodable where Bound: Decodable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    try self.init(container.decode(Bound.self))
  }
}

extension PartialRangeThrough: Encodable where Bound: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(self.upperBound)
  }
}

extension PartialRangeFrom: Decodable where Bound: Decodable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    try self.init(container.decode(Bound.self))
  }
}

extension PartialRangeFrom: Encodable where Bound: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(self.lowerBound)
  }
}
