// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "QEMUBox",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "QEMUBox",
            targets: ["QEMUBox"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "QEMUBox",
            dependencies: [],
            path: "QEMUBoxApp"
        )
    ]
)
