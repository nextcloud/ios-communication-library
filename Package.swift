// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NCCommunication",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "NCCommunication",
            targets: ["NCCommunication"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.4.1")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/yahoojapan/SwiftyXMLParser", .upToNextMajor(from: "5.3.0")),
    ],
    targets: [
        .target(
            name: "NCCommunication",
            dependencies: ["Alamofire","SwiftyJSON","SwiftyXMLParser"],
            path: "NCCommunication"),
        .testTarget(
            name: "NCCommunicationTests",
            dependencies: ["NCCommunication"],
            path: "NCCommunicationTests")
    ]
)
