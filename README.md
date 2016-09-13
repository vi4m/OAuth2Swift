# OAuth2Swift

OAuth2 middleware for Zewo Swift framework. Works well on OSX, Linux and other systems supported by Zewo.

Currently it plays nicely with the Google OAuth2 systems only.

- [x] Token caching in file
- [ ] More providers
- [ ] Tests

See: [Zewo project](https://github.com/Zewo?utf8=✓&query=middleware) for more details.

# Installation

Just add ```.Package(url: "https://github.com/vi4m/OAuth2Swift.git", majorVersion: 0, minor: 1)``` to your Package.swift file and run `swift build` to download dependency.
    
# Usage

In this package, we user only server side OAuth2 with 2 options:
- authorize using refresh tokens (RefreshTokenGrantType) 
- authorize using client credentials (ClientCredentialsGrantType)

In the first case, we will need to generate refresh token first, Google API Auth console allows to do it. Using
this refresh token, and authentication information, we can generate next access tokens. 

In the latter, we will ony need client_id and secret key. 

Some basic URLs will be needed too.

# Refresh Token Grant Type

```swift

    let googleGrantType = RefreshTokenGrantType(clientId: "myapp", clientSecret: "secret", 
                    refreshToken: "token", refreshTokenURL: "/oauth2/v3/token", baseURL: "https://www.googleapis.com:443")

    middleware = OAuth2Middleware(grantType: googleGrantType, tokenFileName: "/tmp/token")
    
    // if token is not present(or expired) it will be redownloaded automatically using refresh_token
    client = try! Client(uri: "https://www.googleapis.com:443")
    
    // example call - remember about putting middleware here
    var response = try client.get("/drive/v3/files", middleware: middleware)
    print(try response.body.becomeBuffer())
```

# Client Credentials Grant Type

```swift

    let clientCredentialsGrantType = ClientCredentialsGrantType(clientId: "myapp", clientSecret: "secret", 
                    authorizeTokenURL: "/auth/oauth/token", baseURL: "https://www.googleapis.com:443")
    middleware = OAuth2Middleware(grantType: clientCredentialsGrantType, tokenFileName: "/tmp/token")
```

    
