// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ScrollableGraphView",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ScrollableGraphView",
            targets: ["ScrollableGraphView"]
        ),
    ],
    targets: [
        .target(
            name: "ScrollableGraphView",
            path: "Classes"
        )
    ]
)
