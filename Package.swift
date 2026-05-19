// swift-tools-version:6.0

// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 Kitura project contributors

import PackageDescription

let package = Package(
  name: "KituraCache",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "KituraCache", targets: ["KituraCache"])
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.5.0"),
  ],
  targets: [
    .target(name: "KituraCache"),
    .testTarget(
      name: "KituraCacheTests",
      dependencies: ["KituraCache"]
    ),
  ]
)
