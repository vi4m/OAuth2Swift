import PackageDescription

let package = Package(
    name: "OAuth2Middleware",
    dependencies: [
          .Package(url: "https://github.com/ZewoGraveyard/CEnvironment.git", majorVersion: 0, minor: 1),
          .Package(url: "https://github.com/vi4m/Zewo.git", majorVersion: 0, minor: 8),
          .Package(url: "https://github.com/Zewo/Base64.git", majorVersion: 0, minor: 12)
    ]
)
