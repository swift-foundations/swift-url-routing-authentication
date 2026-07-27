// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-url-routing-authentication",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
    ],
    products: [
        // Foundation-free credential-routing vocabulary: the Authentication
        // namespace, its typed error, and the Bearer/Basic Authorization-header
        // routers over the RFC credential value types.
        .library(name: "Authentication", targets: ["Authentication"]),
        // Foundation interop: the Authentication.Client composition
        // (Foundation.URL base, URLRequest construction, live URLSession-backed
        // clients) plus the legacy `Authenticating` compat spelling layer.
        .library(
            name: "Authentication Foundation Integration",
            targets: ["Authentication Foundation Integration"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-url-routing.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-dependencies.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-6750.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-7617.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-http-standard.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Authentication",
            dependencies: [
                .product(name: "URLRouting", package: "swift-url-routing"),
                .product(name: "HTTP Standard", package: "swift-http-standard"),
                .product(name: "RFC 6750", package: "swift-rfc-6750"),
                .product(name: "RFC 7617", package: "swift-rfc-7617"),
            ]
        ),
        .target(
            name: "Authentication Foundation Integration",
            dependencies: [
                "Authentication",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "URLRouting", package: "swift-url-routing"),
                .product(name: "URL Routing Foundation Integration", package: "swift-url-routing"),
                .product(name: "RFC 6750", package: "swift-rfc-6750"),
                .product(name: "RFC 7617", package: "swift-rfc-7617"),
            ]
        ),
        .testTarget(
            name: "Authentication Tests",
            dependencies: [
                "Authentication"
            ]
        ),
        .testTarget(
            name: "Authentication Foundation Integration Tests",
            dependencies: [
                "Authentication Foundation Integration",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "URL Routing Foundation Integration", package: "swift-url-routing"),
            ]
        ),
    ]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        ]
}
