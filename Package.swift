import PackageDescription

let package = Package(
    name: "OAuth2Middleware",
    dependencies: [
    .Package(url: "https://github.com/Zewo/Axis.git", majorVersion: 0, minor: 14),
    .Package(url: "https://github.com/Zewo/HTTPClient.git", majorVersion: 0, minor: 14),
    .Package(url: "https://github.com/Zewo/HTTPServer.git", majorVersion: 0, minor: 14)
    ]
)
