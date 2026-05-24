// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Punto",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "PuntoCore", targets: ["PuntoCore"]),
        .library(name: "PuntoSettings", targets: ["PuntoSettings"]),
        .executable(name: "Punto", targets: ["Punto"]),
        .executable(name: "PuntoDiag", targets: ["PuntoDiag"]),
        .executable(name: "PuntoHarness", targets: ["PuntoHarness"]),
        .executable(name: "PuntoCoreTest", targets: ["PuntoCoreTest"]),
        .executable(name: "PuntoSettingsTest", targets: ["PuntoSettingsTest"]),
        .executable(name: "PuntoParityTest", targets: ["PuntoParityTest"])
    ],
    targets: [
        .target(
            name: "PuntoCore",
            path: "Sources/PuntoCore"
        ),
        .target(
            name: "PuntoSettings",
            dependencies: ["PuntoCore"],
            path: "Sources/PuntoSettings"
        ),
        .executableTarget(
            name: "Punto",
            dependencies: ["PuntoCore", "PuntoSettings"],
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
            name: "PuntoSettingsTest",
            dependencies: ["PuntoCore", "PuntoSettings"],
            path: "Sources/PuntoSettingsTest"
        ),
        .executableTarget(
            name: "PuntoParityTest",
            dependencies: ["PuntoCore"],
            path: "Sources/PuntoParityTest"
        )
    ]
)
