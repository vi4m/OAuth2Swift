import PackageDescription

let package = Package(
    name: "OAuth2Middleware",
    dependencies: [
//        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/Zewo/String.git", majorVersion: 0, minor: 7),
//        .Package(url: "https://github.com/VeniceX/File.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/VeniceX/HTTPSClient.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/Zewo/JSON.git", majorVersion: 0, minor: 9)
    ]
)
