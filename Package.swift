import PackageDescription

let package = Package(
    name: "OAuth2Middleware"
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 6),
        .Package(url: "https://github.com/Zewo/Base64.git", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/Zewo/String.git", majorVersion: 0, minor: 7),
    ]
)
