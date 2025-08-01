import SwiftUI
import WebKit

typealias WebViewNavigationResponseHandler = (URL) -> Void

struct WebViewContainer: View {
    let url: URL
    let onUrlDetected: ([String:String]) -> Void
    let config = WebPage.Configuration()
    @State private var page: WebPage = WebPage(navigationDecider: ConfigManager.shared.deciding)
    
    var body: some View {
        WebView(page)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                ConfigManager.shared.onUrlDetected = { params in
                    onUrlDetected(params)
                    
                }
                page.load(url)
            }
    }
}

class ConfigManager {
    static var shared = ConfigManager()
    var deciding = VRPlayerNavigationDeciding()
    var onUrlDetected: ([String:String]) -> Void = { _ in }
    
    func reset() {
        onUrlDetected = { _ in }
    }
    class VRPlayerNavigationDeciding : WebPage.NavigationDeciding {
        
        func decidePolicy(
            for action: WebPage.NavigationAction,
            preferences: inout WebPage.NavigationPreferences
        ) async -> WKNavigationActionPolicy {
            print("host is --- \(action.request.url?.host() ?? "-")")
            if action.request.url?.host() == "vrplayer.space" {
                let params = action.request.url?.queryParameters()
                if let params {
                    ConfigManager.shared.onUrlDetected(params)
                }
            }
            return .allow
        }
    }
}

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
