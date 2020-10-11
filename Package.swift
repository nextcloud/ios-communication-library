// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ios-communication-library",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "ios-communication-library",
            targets: ["ios-communication-library"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.2.2")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/yahoojapan/SwiftyXMLParser", .upToNextMajor(from: "5.2.0")),
    ],
    targets: [
        .target(
            name: "ios-communication-library",
            dependencies: ["Alamofire","SwiftyJSON","SwiftyXMLParser"]),
        .testTarget(
            name: "ios-communication-libraryTests",
            dependencies: ["ios-communication-library"]),
    ]
)
