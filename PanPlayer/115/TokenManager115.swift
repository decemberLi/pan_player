import Foundation
import CommonCrypto

class TokenManager115 {
    static let shared = TokenManager115()
    var token: String?
    var refreshToken: String?
    var expiresIn: Int?
    var lastUpdateTime: Date?
    var state: String?

    var isLogin: Bool {
        get {
            return token != nil
        }
    }

    var isExpired: Bool {
        get {
            guard let expiresIn, let lastUpdateTime else { return true }
            // 过期时间小于当前时间 秒
            return Date().timeIntervalSince(lastUpdateTime) >= Double(expiresIn)
        }
    }

    var requestWebURL: URL {
        get {
            state = UUID().uuidString.md5
            guard let url = URL(string: "https://passportapi.115.com/open/authorize?client_id=100197637&redirect_uri=https://vrplayer.space&response_type=code&state=\(state ?? "123456")") else {
                fatalError("115 token url error")
            }
            return url
        }
    }

    private init() {
        let tokenJson = UserDefaults.standard.string(forKey: "115token")
        guard let tokenData = tokenJson?.data(using: .utf8) else { return }
        guard let tokenJson = try? JSONSerialization.jsonObject(with: tokenData, options: []) as? [String: Any]
              else { return }
        token = tokenJson["access_token"] as? String
        refreshToken = tokenJson["refresh_token"] as? String
        expiresIn = tokenJson["expires_in"] as? Int
    }

    private func update(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        guard let tokenJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
              else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        
        token = tokenJson["access_token"] as? String
        refreshToken = tokenJson["refresh_token"] as? String
        expiresIn = tokenJson["expires_in"] as? Int
        guard let token , let refreshToken , let expiresIn  else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        let newTokenJson: [String: Any] = ["access_token": token, "refresh_token": refreshToken, "expires_in": expiresIn]
        guard let tokenData = try? JSONSerialization.data(withJSONObject: newTokenJson, options: []) else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        guard let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        UserDefaults.standard.set(tokenString, forKey: "115token")
        lastUpdateTime = Date()
    }

    func getToken(code: String) async throws {
        //请求接口 https://vocalremover.us/api/115/authCodeToToken/{code}?state=\(state)
        guard let state else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        var url = URL(string: "https://vocalremover.us/api/115/authCodeToToken/\(code)?state=\(state)")
        #if DEBUG
        url = URL(string: "http://0.0.0.0:8000/api/115/authCodeToToken/\(code)?state=\(state)")
        #endif
        guard let url else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取token失败"])
        }
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        try update(data: data, response: response)
    }

    //https://passportapi.115.com/open/refreshToken
    func refreshToken() async throws {
        guard let refreshToken else {
            throw NSError(domain: "115", code: 1001, userInfo: [NSLocalizedDescriptionKey: "刷新token失败"])
        }
        //post
        let url = URL(string: "https://passportapi.115.com/open/refreshToken")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let postData = "refresh_token=\(refreshToken)"
        request.httpBody = postData.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        try update(data: data, response: response)
    }
}

extension String {
    var md5: String {
        get {
            let data = self.data(using: .utf8)!
            let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                var hash: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
                CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
                return hash
            }
            return hash.map { String(format: "%02x", $0) }.joined()
        }
    }
}
