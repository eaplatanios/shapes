// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shapes",
    dependencies: [
      .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.4.0")
    ],
    targets: [
      .target(
          name: "Shapes",
          dependencies: ["SPMUtility"]),
    ]
)
