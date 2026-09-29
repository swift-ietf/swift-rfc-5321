// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-5321",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 5321",
            targets: ["RFC 5321"]
        ),
        .library(
            name: "RFC 5321 Foundation Integration",
            targets: ["RFC 5321 Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-ietf/swift-rfc-1123.git", branch: "main"),
        .package(
            url: "https://github.com/swift-atoms/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-incits/swift-incits-4-1986.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 5321",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "RFC 1123", package: "swift-rfc-1123"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
            ]
        ),
        .target(
            name: "RFC 5321 Foundation Integration",
            dependencies: [
                .target(name: "RFC 5321")
            ]
        ),
        .testTarget(
            name: "RFC 5321 Foundation Integration Tests",
            dependencies: [
                .target(name: "RFC 5321"),
                .target(name: "RFC 5321 Foundation Integration"),
            ]
        ),
        .testTarget(
            name: "RFC 5321 Tests",
            dependencies: [
                .target(name: "RFC 5321"),
                .product(name: "RFC 1123", package: "swift-rfc-1123"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
