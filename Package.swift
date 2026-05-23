// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Punto",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "PuntoCore", targets: ["PuntoCore"]),
        .executable(name: "Punto", targets: ["Punto"]),
        .executable(name: "PuntoDiag", targets: ["PuntoDiag"]),
        .executable(name: "PuntoHarness", targets: ["PuntoHarness"]),
        .executable(name: "PuntoCoreTest", targets: ["PuntoCoreTest"]),
        .executable(name: "PuntoTest", targets: ["PuntoTest"])
    ],
    targets: [
        .target(
            name: "PuntoCore",
            path: "Sources/PuntoCore"
        ),
        .executableTarget(
            name: "Punto",
            dependencies: ["PuntoCore"],
            path: "Sources/Punto",
            resources: [
                .copy("../../Resources/Assets.xcassets"),
                .copy("../../Resources/Sounds")
            ]
        ),
        .executableTarget(
            name: "PuntoDiag",
            dependencies: ["PuntoCore"],
            path: "Sources/PuntoDiag"
        ),
        .executableTarget(
            name: "PuntoHarness",
            dependencies: [],
            path: "Sources/PuntoHarness"
        ),
        .executableTarget(
            name: "PuntoCoreTest",
            dependencies: ["PuntoCore"],
            path: "Sources/PuntoCoreTest"
        ),
        .executableTarget(
            name: "PuntoTest",
            dependencies: ["PuntoCore"],
            path: "Sources/PuntoTest"
        )
    ]
)
