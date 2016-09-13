import HTTP
import File
import HTTPSClient
import JSON
import Base64


typealias GetNewTokenFunc = () -> String
typealias GetNewCredentialsFunc = () -> String

private var accessToken: String?

private func writeTokenToFile(token: String, filename: String) throws {
    var file: File
    do {
        file = try File(path: filename, mode: .truncateReadWrite)
        try file.write(token, flushing: true)
        try file.close()
    }
    catch {
        throw error
    }
}

private func readTokenFromFile(filename: String) -> String? {
    var file: File
    
    do {
        file = try File(path: filename, mode: .read)
    }
    catch {
        return nil
    }
    
    let contents = try! file.readAllBytes()
    let rez = String(contents).trim()
    
    guard !rez.isEmpty else {
        return nil
    }
    return rez
}

enum OAuth2MiddlewareError: ErrorProtocol {
    case TokenError
}


public struct Token {
    var value: String
}

public protocol GrantType {
    func obtainToken() throws -> Token
}

public struct RefreshTokenGrantType: GrantType {
    var clientId, clientSecret, baseURL, refreshTokenURL, refreshToken: String
    
    public func obtainToken() throws -> Token {
        do {
            let client = try! Client(uri: "\(baseURL)")
            let refreshTokenEncoded = try! refreshToken.percentEncoded(allowing: .uriPasswordAllowed)
            let body = Data("client_id=\(self.clientId)&client_secret=\(self.clientSecret)&refresh_token=\(refreshTokenEncoded)&grant_type=refresh_token")
            let headers: Headers = [
                "Content-Type": "application/x-www-form-urlencoded"
            ]
            var response = try client.post(refreshTokenURL, headers: headers, body: body)
            let buffer = try response.body.becomeBuffer()
            let parsed = try! JSONParser().parse(data: buffer)
            if response.statusCode != 200 {
                print(parsed)
                throw OAuth2MiddlewareError.TokenError
            }
            return Token(value: try parsed.asDictionary()["access_token"]!.asString())
        } catch {
            print("Response error")
            throw OAuth2MiddlewareError.TokenError
        }
    }
}

public struct ClientCredentialsGrantType: GrantType {
    var clientId, clientSecret, baseURL, authorizeTokenURL: String
    var basicAuthCredentials: (String, String)?
    
    public init(clientId: String, clientSecret: String, baseURL: String, authorizeTokenURL: String, basicAuthCredentials: (String, String)? = nil ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.baseURL = baseURL
        self.authorizeTokenURL = authorizeTokenURL
        self.basicAuthCredentials = basicAuthCredentials
    }
    
    public func obtainToken() throws -> Token {
        let client = try! Client(uri: "\(baseURL)")
        let body = Data("client_id=\(self.clientId)&client_secret=\(self.clientSecret)&grant_type=client_credentials")
        var headers: Headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        if let creds = basicAuthCredentials {
            let credentials = Base64.encode("\(creds.0):\(creds.1)")
            headers["Authorization"] = ["Basic \(credentials)"]
        }
        
        do {
            var response = try client.post(authorizeTokenURL,
                                           headers: headers,
                                           body: body)
            let buffer = try response.body.becomeBuffer()
            let parsed = try! JSONParser().parse(data: buffer)
            if response.statusCode != 200 {
                print(parsed)
                throw OAuth2MiddlewareError.TokenError
            }
            return Token(value: try! parsed.asDictionary()["access_token"]!.asString())
        } catch {
            print("Response error")
            throw OAuth2MiddlewareError.TokenError
        }
    }
}


public struct OAuth2Middleware: Middleware {
    var tokenFileName: String
    var grantType: GrantType
    
    public init(grantType: GrantType, tokenFileName: String) {
        self.grantType = grantType
        self.tokenFileName = tokenFileName
        
        if let token = readTokenFromFile(filename: tokenFileName) {
            accessToken = token
        }
    }
    
    func fetchTokenToCache() {
        print("Fetching token to cache...")
        guard let newToken = try? self.grantType.obtainToken() else {
            print("Failed to obtain new token")
            exit(1)
        }
        accessToken = newToken.value
        try! writeTokenToFile(token: accessToken!, filename: tokenFileName)
    }
    
    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request
        var result: Response
        
        /* If not have access token - authorize */
        if accessToken == nil {
            self.fetchTokenToCache()
        }
        request.headers["Authorization"] = ["Bearer \(accessToken!)"]
        result = try chain.respond(to: request)
        
        if result.statusCode == 401  {
            /* Renew */
            self.fetchTokenToCache()
            request.headers["Authorization"] = ["Bearer", "\(accessToken!)"]
            result = try chain.respond(to: request)
        }
        print(request)
        return result
    }
    
}



