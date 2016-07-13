import HTTP
import File
import HTTPSClient
import JSON

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

private func readAccessTokenFromFile(filename: String) -> String? {
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


public struct OAuth2Middleware: Middleware {
    var clientId, clientSecret, refreshToken : String
    var tokenFileName: String
    
    public init(clientId: String, clientSecret: String, refreshToken: String, tokenFileName: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.refreshToken = refreshToken
        self.tokenFileName = tokenFileName
        
        if let token = readAccessTokenFromFile(filename: tokenFileName) {
            accessToken = token
        }
    }
    
    func fetchTokenToCache() {
        if let newToken = self.getNewToken() {
            accessToken = newToken
            try! writeTokenToFile(token: accessToken!, filename: tokenFileName)
        }
        else {
            print("Failed to obtain new token")
            exit(1)
        }
    }
    
    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request
        var result: Response
      
        /* If not have access token - authorize */
        if accessToken == nil {
            self.fetchTokenToCache()
        }
        request.headers["Authorization"] = "Bearer \(accessToken!)"
        result = try chain.respond(to: request)
        
        if result.statusCode == 401  {
            /* Renew */
            self.fetchTokenToCache()
            request.headers["Authorization"] = "Bearer \(accessToken!)"
            result = try chain.respond(to: request)
        }
        print(request)
        return result
    }
    
    func getNewToken() -> String? {
        let client = try! Client(uri: "https://www.googleapis.com:443")
        let refreshTokenEncoded = try! self.refreshToken.percentEncoded(allowing: .uriPasswordAllowed)
        let body = Data("client_id=\(self.clientId)&client_secret=\(self.clientSecret)&refresh_token=\(refreshTokenEncoded)&grant_type=refresh_token")
        let headers: Headers = [
           "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        do {
            var response = try client.post("/oauth2/v3/token", headers: headers, body: body)
            let buffer = try response.body.becomeBuffer()
            let parsed = try! JSONParser().parse(data: buffer)
            if response.statusCode != 200 {
               print(parsed)
               return nil
            }
            return try! parsed.asDictionary()["access_token"]!.asString()
        } catch {
            print("Response error")
            return nil
        }
    }
}


