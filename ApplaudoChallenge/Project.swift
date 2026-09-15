import ProjectDescription

let project = Project(
    name: "ApplaudoChallenge",
    targets: [
        .target(
            name: "ApplaudoChallenge",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.ApplaudoChallenge",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CAT_API_KEY": "$(CAT_API_KEY)",
                ]
            ),
            buildableFolders: [
                "ApplaudoChallenge/Sources",
                "ApplaudoChallenge/Resources",
            ],
            dependencies: [
                .target(name: "NetworkLayer"),
            ],
            settings: .settings(configurations: [
                .debug(name: "Debug", xcconfig: "Config/Secrets.xcconfig"),
                .release(name: "Release", xcconfig: "Config/Secrets.xcconfig"),
            ])
        ),
        .target(
            name: "ApplaudoChallengeTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.ApplaudoChallengeTests",
            infoPlist: .default,
            buildableFolders: [
                "ApplaudoChallenge/Tests"
            ],
            dependencies: [.target(name: "ApplaudoChallenge")]
        ),
        .target(
            name: "NetworkLayer",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.tuist.NetworkLayer",
            infoPlist: .default,
            buildableFolders: [
                "modules/NetworkLayer/Sources",
            ],
            dependencies: [
                .external(name: "Moya"),
            ]
        ),
        .target(
            name: "NetworkLayerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.NetworkLayerTests",
            infoPlist: .default,
            buildableFolders: [
                "modules/NetworkLayer/NetworkLayerTest",
            ],
            dependencies: [.target(name: "NetworkLayer")]
        ),
    ]
)
