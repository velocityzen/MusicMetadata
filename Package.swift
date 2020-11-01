// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "MusicMetadata",
  products: [
    .library(
      name: "MusicMetadata",
      targets: ["MusicMetadata"]),
  ],
  dependencies: [
    .package(url: "https://github.com/velocityzen/FileType", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "MusicMetadata",
      dependencies: ["FileType"]),
    
    .testTarget(
      name: "MusicMetadataTests",
      dependencies: ["MusicMetadata"]),
  ]
)
