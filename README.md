# OAuth2Swift

OAuth2 middleware for Zewo Swift framework. 

Currently it plays nicely with the Google OAuth2 systems only.

- [x] Token caching in file
- [ ] More providers
- [ ] Tests

See: [Zewo project](https://github.com/Zewo?utf8=✓&query=middleware) for more details.

# Installation

Just add ```.Package(url: "https://github.com/vi4m/OAuth2Swift.git", majorVersion: 0, minor: 1)``` to your Package.swift file and run `swift build` to download dependency.
    
# Usage
    
```swift

    middleware = OAuth2Middleware(clientId: clientId, clientSecret: clientSecret, 
        refreshToken: refreshToken, tokenFileName: "/tmp/token")
    
    // if token is not present(or expired) it will be redownloaded automatically using refresh_token
    client = try! Client(uri: "https://www.googleapis.com:443")
    
    // example call - remember about putting middleware here
    var response = try client.get("/drive/v3/files", middleware: middleware)
    print(try response.body.becomeBuffer())
```
