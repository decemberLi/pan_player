import Foundation
// FileData115 model is in the same directory

class DataManager115 {
    static let shared = DataManager115()
    private init() {}

    ///open/ufile/files
    /// 获取文件列表
    func getFileList(cid: String?,limit: Int = 100,offset: Int = 0) async throws -> FileData115 {
        if TokenManager115.shared.isExpired {
            try await TokenManager115.shared.refreshToken()
        }
        //请求接口 https://passportapi.115.com/open/ufile/files
        let url = URL(string: "https://proapi.115.com/open/ufile/files")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "cid", value: cid),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "cur", value: "1"),
            URLQueryItem(name: "show_dir", value: "1")
        ]
        let headers = [
            "Authorization": "Bearer \(TokenManager115.shared.token ?? "")"
        ]
        var request = URLRequest(url: components!.url!)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "GET"
        
        // 添加认证token
        if let token = TokenManager115.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TokenManagerError.networkError
        }
        
        // 使用FileData115模型解析数据
        let decoder = JSONDecoder()
        #if DEBUG
        let logString = String(data: data, encoding: .utf8)
        print("result -- \(logString ?? "")")
        #endif
        let fileData = try decoder.decode(FileData115.self, from: data)
        return fileData
    }

    ///open/video/play
    /// 获取视频播放地址
    func getVideoPlayURL(pick_code: String) async throws -> VideoData115 {
        //请求接口 https://passportapi.115.com/open/video/play
        if TokenManager115.shared.isExpired {
            try await TokenManager115.shared.refreshToken()
        }
        let url = URL(string: "https://proapi.115.com/open/video/play")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "pick_code", value: pick_code)
        ]
        let headers = [
            "Authorization": "Bearer \(TokenManager115.shared.token ?? "")"
        ]
        var request = URLRequest(url: components!.url!)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TokenManagerError.networkError
        }
        #if DEBUG
        let logString = String(data: data, encoding: .utf8)
        print("video result -- \(logString ?? "")")
        #endif
        // 使用VideoData115模型解析数据
        let decoder = JSONDecoder()
        let videoData = try decoder.decode(VideoData115.self, from: data)
        return videoData
    }

    ///open/ufile/downurl
    /// 获取文件下载地址
    func getFileDownloadURL(pick_code: String) async throws -> String {
        //请求接口 https://passportapi.115.com/open/ufile/downurl
        //请求参数是form-data形式放到body里面
        if TokenManager115.shared.isExpired {
            try await TokenManager115.shared.refreshToken()
        }
        let url = URL(string: "https://proapi.115.com/open/ufile/downurl")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "pick_code", value: pick_code)
        ]
        let headers = [
            "Authorization": "Bearer \(TokenManager115.shared.token ?? "")"
        ]
        var request = URLRequest(url: components!.url!)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()

        // Add text field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"pick_code\"\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(pick_code.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // Final closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TokenManagerError.networkError
        }
        #if DEBUG
        let logString = String(data: data, encoding: .utf8)
        print("file download result -- \(logString ?? "")")
        #endif
        // 使用FileData115模型解析数据
        let map = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let mapData = map["data"] as? [String: Any]
        let values = mapData?.values.first as? [String:Any]
        let fileURL = values?["url"] as? [String:Any]
        let realURL = fileURL?["url"] as? String
        return realURL ?? ""
    }
}
