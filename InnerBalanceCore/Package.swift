// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "InnerBalanceCore",
  platforms: [
    .iOS(.v18),
    .watchOS(.v11),
    .macOS(.v15),
  ],
  products: [
    .library(name: "InnerBalanceCore", targets: ["InnerBalanceCore"])
  ],
  targets: [
    .target(name: "InnerBalanceCore"),
    .testTarget(
      name: "InnerBalanceCoreTests",
      dependencies: ["InnerBalanceCore"]
    ),
  ]
)
