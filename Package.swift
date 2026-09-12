// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "PuntoNative", platforms: [.macOS(.v14)], products: [.executable(name: "PuntoNative", targets: ["PuntoNative"])], targets: [.target(name: "PuntoCore"), .executableTarget(name: "PuntoNative", dependencies: ["PuntoCore"]), .executableTarget(name: "PuntoChecks", dependencies: ["PuntoCore"], path: "Tests/PuntoCoreTests")], swiftLanguageModes: [.v5])
