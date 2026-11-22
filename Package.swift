// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PuntoNative",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PuntoNative", targets: ["PuntoNative"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.1")],
    targets: [
        .target(name: "PuntoCore"),
        .executableTarget(
            name: "PuntoNative",
            dependencies: ["PuntoCore", .product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .executableTarget(name: "PuntoChecks", dependencies: ["PuntoCore"], path: "Tests/PuntoCoreTests")
    ],
    swiftLanguageModes: [.v5]
)
