// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "ImageResizeDialog",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "ImageResizeDialog",
            path: "Sources/ImageResizeDialog",
            exclude: ["Info.plist"]
        )
    ]
)
