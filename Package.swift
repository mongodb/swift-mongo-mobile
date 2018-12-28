// swift-tools-version:4.0
import PackageDescription
let package = Package(
    name: "MongoMobile",
    products: [
        .library(name: "MongoMobile", targets: ["MongoMobile"])
    ],
    targets: [
        .target(name: "MongoMobile"),
	.testTarget(name: "MongoMobileTests", dependencies: ["MongoMobile"])
    ]
)
