// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "audio_session", path: "../.packages/audio_session-0.1.25"),
        .package(name: "audioplayers_darwin", path: "../.packages/audioplayers_darwin-6.3.0"),
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-6.1.0"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.1.2"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.2.1"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.4.4"),
        .package(name: "record_macos", path: "../.packages/record_macos-1.1.2"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "speech_to_text", path: "../.packages/speech_to_text-7.3.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "audioplayers-darwin", package: "audioplayers_darwin"),
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "record-macos", package: "record_macos"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "speech-to-text", package: "speech_to_text"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
