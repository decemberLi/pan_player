//
//  LocalHTTPProxy.swift
//  PanPlayer
//
//  A minimal local HTTP proxy that forwards GET requests (with Range)
//  to a remote URL and streams the response back to the client.
//

import Foundation
import Network

final class LocalHTTPProxy: NSObject {
    static let shared = LocalHTTPProxy()

    private var listener: NWListener?
    private var port: NWEndpoint.Port?
    private let queue = DispatchQueue(label: "LocalHTTPProxy.queue")

    // Keep strong references to in-flight proxy sessions
    private var activeSessions: Set<ProxySession> = []

    func start() {
        guard listener == nil else { return }
        do {
            let listener = try NWListener(using: .tcp, on: 0)
            self.listener = listener

            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.port = listener.port
                    print("[LocalHTTPProxy] ready on port: \(listener.port?.rawValue ?? 0)")
                case .failed(let error):
                    print("[LocalHTTPProxy] failed: \(error)")
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                if let endpoint = connection.endpoint.debugDescription as String? {
                    print("[LocalHTTPProxy] new connection: \(endpoint)")
                }
                self?.handle(connection: connection)
            }

            listener.start(queue: queue)
        } catch {
            print("[LocalHTTPProxy] start error: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        port = nil
        queue.async { [weak self] in
            self?.activeSessions.removeAll()
        }
    }

    func proxyURL(for remoteURL: URL) -> URL {
        start()
        let portValue = port?.rawValue ?? 0
        // 手动构造，并对整个嵌套 URL 做一次标准的 percent-encoding（包括 % 也会被转义为 %25）。
        // 代理端将只解码一次，从而把 %25 还原为 %，最终得到原始直链（其中原始的 %40 会被还原为 %40 而非 @）。
        let raw = remoteURL.absoluteString
        let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let allowed = CharacterSet(charactersIn: unreserved)
        let encoded = raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
        let urlString = "http://127.0.0.1:\(portValue)/proxy?url=\(encoded)"
        print("[LocalHTTPProxy] build proxyURL for: \(raw), port=\(portValue)")
        return URL(string: urlString) ?? URL(string: "http://127.0.0.1:\(portValue)/proxy")!
    }

    // MARK: - Connection Handling
    private func handle(connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                print("LocalHTTPProxy connection failed: \(error)")
            }
        }
        connection.start(queue: queue)
        receiveRequest(on: connection, accumulated: Data())
    }

    private func receiveRequest(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let error = error {
                print("[LocalHTTPProxy] receive error: \(error)")
                connection.cancel()
                return
            }

            var buffer = accumulated
            if let data = data { buffer.append(data) }

            // Look for end of headers (CRLFCRLF)
            if let range = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let headerData = buffer.subdata(in: 0..<range.upperBound)
                let bodyRemainder = buffer.suffix(from: range.upperBound)
                self.handleHTTPRequest(headerData: headerData, bodyRemainder: bodyRemainder, on: connection)
                return
            }

            if isComplete {
                // Invalid/short request
                print("[LocalHTTPProxy] request closed before headers parsed")
                connection.cancel()
                return
            }

            // Continue reading
            self.receiveRequest(on: connection, accumulated: buffer)
        }
    }

    private func handleHTTPRequest(headerData: Data, bodyRemainder: Data, on connection: NWConnection) {
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            connection.cancel(); return
        }
        let lines = headerString.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else { connection.cancel(); return }

        // Parse request line: GET /proxy?url=... HTTP/1.1
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 3 else { connection.cancel(); return }
        let method = String(parts[0])
        let target = String(parts[1])
        _ = String(parts[2]) // http version ignored
        print("[LocalHTTPProxy] request: \(method) \(target)")

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            if line.isEmpty { break }
            if let idx = line.firstIndex(of: ":") {
                let name = line[..<idx].trimmingCharacters(in: .whitespaces)
                let value = line[line.index(after: idx)...].trimmingCharacters(in: .whitespaces)
                headers[name.lowercased()] = value
            }
        }

        guard method == "GET" || method == "HEAD" else { print("[LocalHTTPProxy] reject method=\(method)"); sendSimpleResponse(code: 405, message: "Method Not Allowed", on: connection); return }
        // Preserve percent-encoding of the nested 'url' param; don't use URLComponents.value (which decodes once).
        // First, verify path is /proxy
        var pathIsProxy = false
        if let comps = URLComponents(string: target) { pathIsProxy = comps.path == "/proxy" } else { pathIsProxy = target.hasPrefix("/proxy") }
        guard pathIsProxy else {
            print("[LocalHTTPProxy] bad path: \(target)")
            sendSimpleResponse(code: 400, message: "Bad Request", on: connection); return
        }
        let rawRemoteStr: String? = {
            // 只支持单参数：url=<encoded url>，取整段剩余，不再按 & 切分，避免截断内部查询
            if let range = target.range(of: "url=") {
                return String(target[range.upperBound...])
            }
            return nil
        }()
        // 客户端通常会对 query 进行一次百分号转义（% -> %25），这里需要解码一次还原原始直链
        let decodedOnce = rawRemoteStr?.removingPercentEncoding
        guard let restored = decodedOnce ?? rawRemoteStr else {
            print("[LocalHTTPProxy] url param missing/invalid. target=\(target) rawUrl=\(String(describing: rawRemoteStr))")
            sendSimpleResponse(code: 400, message: "Bad Request", on: connection); return
        }

        let rangeValue = headers["range"]
        print("[LocalHTTPProxy] forward -> raw=\(rawRemoteStr ?? "<nil>") restored=\(restored) range=\(rangeValue ?? "<nil>") method=\(method)")
        let session = ProxySession(rawURLString: restored, method: method, clientConnection: connection, rangeHeader: rangeValue, queue: queue)
        session.completion = { [weak self] finishedSession in
            self?.queue.async { [weak self] in
                self?.activeSessions.remove(finishedSession)
            }
        }
        queue.async { [weak self] in
            guard let self else { return }
            self.activeSessions.insert(session)
            session.start()
        }
    }

    private func sendSimpleResponse(code: Int, message: String, on connection: NWConnection) {
        let status = "HTTP/1.1 \(code) \(message)\r\n"
        let headers = [
            "Content-Type: text/plain",
            "Connection: close",
            "Content-Length: \(message.utf8.count)"
        ].joined(separator: "\r\n") + "\r\n\r\n"
        let body = Data(message.utf8)
        let data = Data((status + headers).utf8) + body
        connection.send(content: data, completion: .contentProcessed({ _ in
            print("[LocalHTTPProxy] respond \(code) \(message)")
            connection.cancel()
        }))
    }
}

// MARK: - ProxySession

private final class ProxySession: NSObject, URLSessionDataDelegate {
    // 每段最大传输大小（8 MiB）
    private static let maxChunkSize: Int64 = 8 * 1024 * 1024
    let rawURLString: String
    let method: String
    let clientConnection: NWConnection
    let rangeHeader: String?
    let queue: DispatchQueue
    var completion: ((ProxySession) -> Void)?

    private var urlSession: URLSession!
    private var totalBytesForwarded: Int64 = 0
    private var statusCode: Int = 0
    private var errorSnippet = Data()
    private var didSendResponseHeaders = false
    private var clientClosed = false

    init(rawURLString: String, method: String, clientConnection: NWConnection, rangeHeader: String?, queue: DispatchQueue) {
        self.rawURLString = rawURLString
        self.method = method
        self.clientConnection = clientConnection
        self.rangeHeader = rangeHeader
        self.queue = queue
        super.init()
        let config = URLSessionConfiguration.ephemeral
        // Do not cache to disk; we want streaming
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func start() {
        // 使用原始字符串构造，避免 Foundation 对某些字符的再编码
        guard let url = URL(string: rawURLString) else {
            sendError(code: 400, message: "Bad URL"); return
        }
        var request = URLRequest(url: url)
        // AVFoundation 常用 HEAD 探测长度；部分源对 HEAD 不友好，转换为 GET Range: bytes=0-0
        let upstreamMethod: String
        if method == "HEAD" {
            upstreamMethod = "GET"
            request.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        } else {
            upstreamMethod = method
        }
        request.httpMethod = upstreamMethod
        // 计算上游 Range：对 GET 的 Range 做分段上限，避免一次性拉取过大
        if upstreamMethod == "GET" {
            let adjusted = computeClampedRangeHeader(from: rangeHeader)
            if let adjusted {
                request.setValue(adjusted, forHTTPHeaderField: "Range")
            }
        } else if let rangeHeader {
            // 非 GET（例如未来扩展）就透传
            request.setValue(rangeHeader, forHTTPHeaderField: "Range")
        }
        // 尽量最小化自定义头，模拟地址栏直接打开
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        print("[LocalHTTPProxy] ProxySession start -> client=\(method) upstream=\(upstreamMethod) \(rawURLString) range=\(rangeHeader ?? "<nil>") -> upstreamRange=\(request.value(forHTTPHeaderField: "Range") ?? "<none>")")
        let task = urlSession.dataTask(with: request)
        task.resume()

        // 监听客户端连接状态，客户端断开则尽快中止上游请求
        clientConnection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .failed(let err):
                self.clientClosed = true
                self.urlSession.invalidateAndCancel()
                print("[LocalHTTPProxy] client connection failed: \(err)")
            case .waiting(let err):
                print("[LocalHTTPProxy] client connection waiting: \(err)")
            case .cancelled:
                self.clientClosed = true
                self.urlSession.invalidateAndCancel()
                print("[LocalHTTPProxy] client connection cancelled")
            default:
                break
            }
        }
    }

    // 解析客户端 Range，并限制单次请求的最大范围（maxChunkSize）。
    // 返回调整后的 Range 头字符串；如果客户端未带 Range，则从 0 开始按上限返回。
    private func computeClampedRangeHeader(from original: String?) -> String? {
        let maxSize = ProxySession.maxChunkSize
        guard let original, original.lowercased().hasPrefix("bytes=") else {
            // 无 Range：从 0 开始按上限
            return "bytes=0-\(maxSize - 1)"
        }
        let pattern = "bytes=\\s*([0-9]*)-([0-9]*)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let ns = original as NSString
            let range = NSRange(location: 0, length: ns.length)
            if let match = regex.firstMatch(in: original, options: [], range: range) {
                let startStr = match.range(at: 1).location != NSNotFound ? ns.substring(with: match.range(at: 1)) : ""
                let endStr = match.range(at: 2).location != NSNotFound ? ns.substring(with: match.range(at: 2)) : ""
                let hasStart = !startStr.isEmpty
                let hasEnd = !endStr.isEmpty
                if hasStart {
                    let start = Int64(startStr) ?? 0
                    if hasEnd {
                        let end = Int64(endStr) ?? start
                        // clamp 到 start + maxSize - 1
                        let clampedEnd = min(end, start + maxSize - 1)
                        return "bytes=\(start)-\(clampedEnd)"
                    } else {
                        // bytes=start-  -> 限制到 start + maxSize - 1
                        let clampedEnd = start + maxSize - 1
                        return "bytes=\(start)-\(clampedEnd)"
                    }
                } else if hasEnd {
                    // bytes=-suffixLen  保持原样（通常请求最后 N 字节，不改动）
                    return original
                }
            }
        }
        // 不匹配则回退：从 0 开始按上限
        return "bytes=0-\(maxSize - 1)"
    }

    // MARK: URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let http = response as? HTTPURLResponse else {
            sendError(code: 502, message: "Bad Gateway"); completionHandler(.cancel); return
        }

        statusCode = http.statusCode
        var statusLine = "HTTP/1.1 \(http.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: http.statusCode).capitalized)\r\n"

        var headerLines: [String] = []
        func copyHeader(_ key: String) {
            if let value = http.value(forHTTPHeaderField: key) { headerLines.append("\(key): \(value)") }
        }
        // Forward common headers for media playback
        copyHeader("Content-Type")
        copyHeader("Content-Length")
        copyHeader("Accept-Ranges")
        copyHeader("Content-Range")
        copyHeader("ETag")
        copyHeader("Last-Modified")

        headerLines.append("Connection: close")

        let headerData = Data((statusLine + headerLines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
        clientConnection.send(content: headerData, completion: .contentProcessed({ [weak self] _ in
            if let self, self.statusCode == 206 {
                // 对于分块范围响应，及时 flush 头部，有助于播放器尽快开始读取
            }
        }))
        didSendResponseHeaders = true
        print("[LocalHTTPProxy] upstream status=\(http.statusCode) ct=\(http.value(forHTTPHeaderField: "Content-Type") ?? "-") cl=\(http.value(forHTTPHeaderField: "Content-Length") ?? "-") cr=\(http.value(forHTTPHeaderField: "Content-Range") ?? "-")")
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytesForwarded += Int64(data.count)
        if statusCode >= 400 && errorSnippet.count < 512 {
            let remain = 512 - errorSnippet.count
            if remain > 0 { errorSnippet.append(data.prefix(remain)) }
        }
        // 对于客户端的 HEAD 请求，丢弃正文，仅依靠响应头
        if method == "HEAD" {
            return
        }
        if clientClosed { return }
        clientConnection.send(content: data, completion: .contentProcessed({ _ in }))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("[LocalHTTPProxy] ProxySession complete with error: \(error), bytes=\(totalBytesForwarded)")
        } else {
            if statusCode >= 400 {
                let snippet = String(data: errorSnippet, encoding: .utf8) ?? errorSnippet.base64EncodedString()
                print("[LocalHTTPProxy] ProxySession complete http=\(statusCode), bytes=\(totalBytesForwarded), body=\(snippet))")
            } else {
                print("[LocalHTTPProxy] ProxySession complete ok, http=\(statusCode), bytes=\(totalBytesForwarded)")
            }
        }
        clientConnection.send(content: nil, isComplete: true, completion: .contentProcessed({ [weak self] _ in
            guard let self else { return }
            self.clientConnection.cancel()
            self.urlSession.invalidateAndCancel()
            self.completion?(self)
        }))
    }

    private func sendError(code: Int, message: String) {
        let statusLine = "HTTP/1.1 \(code) \(message)\r\n"
        let headers = "Content-Type: text/plain\r\nConnection: close\r\nContent-Length: \(message.utf8.count)\r\n\r\n"
        let data = Data((statusLine + headers).utf8) + Data(message.utf8)
        clientConnection.send(content: data, completion: .contentProcessed({ [weak self] _ in
            guard let self else { return }
            self.clientConnection.cancel()
            self.urlSession.invalidateAndCancel()
            print("[LocalHTTPProxy] sendError: \(code) \(message)")
            self.completion?(self)
        }))
    }
}



