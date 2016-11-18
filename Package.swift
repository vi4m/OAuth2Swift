import PackageDescription

let package = Package(
    name: "OAuth2Middleware",
    dependencies: [
    .Package(url: "https://github.com/vi4m/Zewo.git", majorVersion: 0, minor: 14)
    ]
)
