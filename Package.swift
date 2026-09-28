// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Espalier",
    platforms: [.macOS(.v14), .iOS(.v16), .tvOS(.v16)],
    products: [
        .library(name: "LayoutCore", targets: ["LayoutCore"]),
        .library(name: "ThemeCore", targets: ["ThemeCore"]),
        .library(name: "StateCore", targets: ["StateCore"]),
        .library(name: "Nodes", targets: ["Nodes"]),
    ],
    dependencies: [
        .package(url: "https://github.com/resoul/AsyncRay.git", exact: "1.0.0")
    ],
    targets: [
        .target(name: "LayoutCore"),
        .target(name: "ThemeCore", dependencies: ["LayoutCore"]),
        .target(name: "StateCore"),
        .target(name: "Nodes", dependencies: ["LayoutCore", "StateCore", "ThemeCore"]),
    ]
)
