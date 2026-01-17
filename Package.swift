// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Punto",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Punto", targets: ["Punto"]),
        .executable(name: "PuntoDiag", targets: ["PuntoDiag"]),
        .executable(name: "PuntoTest", targets: ["PuntoTest"])
    ],
    targets: [
        .executableTarget(
            name: "Punto",
            path: "Sources/Punto",
            resources: [
                .copy("../../Resources/Assets.xcassets")
            ]
        ),
        .executableTarget(
            name: "PuntoDiag",
            dependencies: [],
            path: "Sources/PuntoDiag"
        ),
        .executableTarget(
            name: "PuntoTest",
            dependencies: [],
            path: "Sources/PuntoTest"
        )
    ]
)
