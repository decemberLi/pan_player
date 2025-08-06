import Foundation

enum TokenManagerError: Error {
    case invalidToken
    case networkError
    case invalidState
    
    var localizedDescription: String {
        switch self {
        case .invalidToken:
            return "获取token失败"
        case .networkError:
            return "网络请求失败"
        case .invalidState:
            return "状态验证失败"
        }
    }
}

class TokenManager115 {
    static let shared = TokenManager115()
    private static let tokenKey = "115token"
    private static let clientID = "100197637"
    private static let redirectURI = "https://vrplayer.space"
    
    var token: String?
    var refreshToken: String?
    var expiresIn: Int?
    var lastUpdateTime: Date?
    var state: String?

    var isLogin: Bool {
        return token != nil
    }

    var isExpired: Bool {
        guard let expiresIn, let lastUpdateTime else { return true }
        // 过期时间小于当前时间 秒
        let result = Date().timeIntervalSince(lastUpdateTime)
        return result >= Double(expiresIn)
    }

    var requestWebURL: URL {
        get {
            state = UUID().uuidString.md5
            
            var components = URLComponents()
            components.scheme = "https"
            components.host = "passportapi.115.com"
            components.path = "/open/authorize"
            components.queryItems = [
                URLQueryItem(name: "client_id", value: TokenManager115.clientID),
                URLQueryItem(name: "redirect_uri", value: TokenManager115.redirectURI),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "state", value: state ?? "123456")
            ]
            
            guard let url = components.url else {
                fatalError("115 token url error")
            }
            return url
        }
    }

    private init() {
        let tokenJson = UserDefaults.standard.string(forKey: TokenManager115.tokenKey)
        guard let tokenData = tokenJson?.data(using: .utf8) else { return }
        let jsonString = String(data: tokenData, encoding: .utf8)
        print("token json -- \(jsonString ?? "")")
        guard let tokenJson = try? JSONSerialization.jsonObject(with: tokenData, options: []) as? [String: Any]
              else { return }
        token = tokenJson["access_token"] as? String
        refreshToken = tokenJson["refresh_token"] as? String
        expiresIn = tokenJson["expires_in"] as? Int
        let lastTimeSaved = UserDefaults.standard.double(forKey: "115lastUpdateTime")
        if lastTimeSaved != 0 {
            lastUpdateTime = Date(timeIntervalSince1970: lastTimeSaved)
        }
    }

    private func update(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TokenManagerError.networkError
        }
        
        guard let tokenJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw TokenManagerError.invalidToken
        }
        
        print("get token \(tokenJson)")
        guard let jsonData = tokenJson["data"] as? [String:Any] else {
            throw TokenManagerError.invalidToken
        }
        
        guard let accessToken = jsonData["access_token"] as? String,
              let refreshToken = jsonData["refresh_token"] as? String,
              let expiresIn = jsonData["expires_in"] as? Int else {
            throw TokenManagerError.invalidToken
        }
        
        self.token = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        
        let newTokenJson: [String: Any] = [
            "access_token": accessToken,
            "refresh_token": refreshToken,
            "expires_in": expiresIn
        ]
        
        guard let tokenData = try? JSONSerialization.data(withJSONObject: newTokenJson, options: []),
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw TokenManagerError.invalidToken
        }
        
        UserDefaults.standard.set(tokenString, forKey: TokenManager115.tokenKey)
        lastUpdateTime = Date()
        UserDefaults.standard.set(lastUpdateTime?.timeIntervalSince1970, forKey: "115lastUpdateTime")
    }

    func getToken(code: String,stateString:String) async throws {
        //请求接口 https://vocalremover.us/api/115/authCodeToToken/{code}?state=\(state)
        state = stateString
        guard let state else {
            throw TokenManagerError.invalidState
        }
        
        let baseURL = "https://vocalremover.us/api/115/authCodeToToken"
        
        var components = URLComponents(string: baseURL)
        components?.path = "/api/115/authCodeToToken/\(code)"
        components?.queryItems = [URLQueryItem(name: "state", value: state)]
        
        guard let url = components?.url else {
            throw TokenManagerError.invalidToken
        }
        print("token request url = \(url)")
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try update(data: data, response: response)
    }

    //https://passportapi.115.com/open/refreshToken
    func refreshToken() async throws {
        guard let refreshToken else {
            throw TokenManagerError.invalidToken
        }
        
        //post
        guard let url = URL(string: "https://passportapi.115.com/open/refreshToken") else {
            throw TokenManagerError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()

        // Add text field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"refresh_token\"\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(refreshToken.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // Final closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try update(data: data, response: response)
    }
    
    func clear(){
        token = nil
        refreshToken = nil
        expiresIn = nil
        lastUpdateTime = nil
        state = nil
    }
}

