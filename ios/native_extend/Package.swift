// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "native_extend",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "native-extend", targets: ["native_extend"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "native_extend_internal",
            path: "Sources/native_extend_internal",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedLibrary("resolv")
            ]
        ),
        .target(
            name: "native_extend",
            dependencies: ["native_extend_internal"],
            path: "Sources/native_extend"
        )
    ]
)
