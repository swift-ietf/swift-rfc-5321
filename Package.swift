// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-5321",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
    ],
    products: [
        .library(name: "RFC 5321", targets: ["RFC 5321"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-ascii-serializer-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-binary-serializer-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-ascii-parser-primitives.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-incits/swift-incits-4-1986.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-1123.git", branch: "main"),
        .package(
            url: "https://github.com/swift-primitives/swift-parser-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "RFC 5321",
            dependencies: [
                .product(name: "RFC 1123", package: "swift-rfc-1123"),
                .product(
                    name: "ASCII Serializer Primitives",
                    package: "swift-ascii-serializer-primitives"
                ),
                .product(
                    name: "Binary Serializable Primitives",
                    package: "swift-binary-serializer-primitives"
                ),
                .product(
                    name: "Parseable ASCII Primitives",
                    package: "swift-ascii-parser-primitives"
                ),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
            ]
        ),
        .testTarget(
            name: "RFC 5321 Tests",
            dependencies: [
                "RFC 5321"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
