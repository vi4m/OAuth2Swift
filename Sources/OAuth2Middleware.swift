import Foundation
import HTTP
import File
import HTTPClient
import Axis

var logger = Logger(name: "Configuration Service", appenders: [StandardOutputAppender(levels: .info)])


private func writeTokenToFile(token: String, filename: String) throws {
    var file: File
    do {
        file = try File(path: filename, mode: .truncateReadWrite)
        try file.write(token)
        file.close()
        return String(data: data, encoding: .utf8)
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
    
    let contents = try! file.readAll()
    // fixme: describing?
    let rez = try! String(data: contents)
    
    guard !rez.isEmpty else {
        return nil

    return rez
 }



extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}


typealias GetNewTokenFunc = () -> String
typealias GetNewCredentialsFunc = () -> String

private var accessToken: String?


enum OAuth2MiddlewareError: Error {
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
            let client = try! Client(url: "\(baseURL)")
            let refreshTokenEncoded =  refreshToken.percentEncoded(allowing: .uriPasswordAllowed)
            let body = "client_id=\(self.clientId)&client_secret=\(self.clientSecret)&refresh_token=\(refreshTokenEncoded)&grant_type=refresh_token"
            let headers: Headers = [
                "Content-Type": "application/x-www-form-urlencoded"
            ]
            var response = try client.request(Request(method: .post, url: refreshTokenURL, headers: headers, body: body)!)
            
            let buffer = try response.body.becomeBuffer(deadline: .never)
            let parsed = try! JSONMapParser().parse(buffer)
            if response.statusCode != 200 {
                print(parsed)
                throw OAuth2MiddlewareError.TokenError
            }
            return Token(value: try parsed!.asDictionary()["access_token"]!.asString())
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
        let client = try! Client(url: "\(baseURL)")
        let body = "client_id=\(self.clientId)&client_secret=\(self.clientSecret)&grant_type=client_credentials"
        var headers: Headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        if let creds = basicAuthCredentials {
            
            let credentials = "\(creds.0):\(creds.1)".toBase64()
            headers["Authorization"] = "Basic \(credentials)"
        }
        
        do {
            var response = try client.request(Request(method: .post, url: authorizeTokenURL,
                headers: headers,
                body: body)!)
            let buffer = try response.body.becomeBuffer(deadline: .never)
            let parsed = try! JSONMapParser().parse(buffer)
            if response.statusCode != 200 {
                print(parsed)
                throw OAuth2MiddlewareError.TokenError
            }
            return Token(value: try! parsed!.asDictionary()["access_token"]!.asString())
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
        
        if let token = try? String(contentsOfFile: tokenFileName, encoding: .utf8) {
            accessToken = token
        }
    }
    
    func fetchTokenToCache() throws {
        logger.info("Fetching token to cache...")
        guard let newToken = try? self.grantType.obtainToken() else {
            print("Failed to obtain new token")
            exit(1)
        }
        accessToken = newToken.value
        
        try accessToken!.write(toFile: tokenFileName, atomically: true, encoding: .utf8)
    }
    
    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request
        var result: Response
        
        /* If not have access token - authorize */
        if accessToken == nil {
            try self.fetchTokenToCache()
        }
        logger.debug(accessToken!)
        
        request.headers["Authorization"] = "Bearer \(accessToken!)"
        result = try chain.respond(to: request)
        
        if result.statusCode == 401  {
            /* Renew */
            try self.fetchTokenToCache()
            request.headers["Authorization"] = "Bearer \(accessToken!)"
            result = try chain.respond(to: request)
        }
        logger.debug(request)
        return result
    }
    
}



