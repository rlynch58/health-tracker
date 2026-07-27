// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HealthTrackerNative",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        // Data-model layer only: SwiftData models, local-calendar date-key
        // helpers, numeric ceilings, and the two store types. No UI, no app
        // entry point, no CloudKit entitlements -- those come later.
        .library(
            name: "HealthTrackerData",
            targets: ["HealthTrackerData"]
        ),
    ],
    targets: [
        .target(
            name: "HealthTrackerData"
        ),
        .testTarget(
            name: "HealthTrackerDataTests",
            dependencies: ["HealthTrackerData"]
        ),
    ]
)
