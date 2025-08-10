import SwiftUI
import WebKit

typealias WebViewNavigationResponseHandler = (URL) -> Void

struct WebViewContainer: View {
    let url: URL
    let onUrlDetected: ([String: String]) -> Void

    var body: some View {
        WKWebViewRepresentable(url: url, onUrlDetected: onUrlDetected)
            .ignoresSafeArea()
    }
}

// MARK: - WKWebView SwiftUI 封装，替代仅 visionOS 2.6 起可用的 WebPage/NavigationDeciding
#if os(iOS) || os(visionOS)
private struct WKWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let onUrlDetected: ([String: String]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 避免重复加载同一 URL
        if uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WKWebViewRepresentable

        init(parent: WKWebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let hostString = navigationAction.request.url?.host ?? "-"
            print("host is --- \(hostString)")

            if navigationAction.request.url?.host == "vrplayer.space" {
                if let params = navigationAction.request.url?.queryParameters() {
                    parent.onUrlDetected(params)
                }
            }
            decisionHandler(.allow)
        }
    }
}
#endif

extension URL {
    func queryParameters() -> [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}
