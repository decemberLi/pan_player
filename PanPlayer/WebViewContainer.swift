import SwiftUI
import WebKit

typealias WebViewNavigationResponseHandler = (URL) -> Void

struct WebViewContainer: View {
    let url: URL
    let onUrlDetected: (String) -> Void
    let config = WebPage.Configuration()
    @State private var page: WebPage = WebPage(navigationDecider: ConfigManager.shared.deciding)
    
    var body: some View {
        WebView(page)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                page.load(url)
            }
    }
}

class ConfigManager {
    static var shared = ConfigManager()
    var deciding = VRPlayerNavigationDeciding()
    
    class VRPlayerNavigationDeciding : WebPage.NavigationDeciding {
        
        func decidePolicy(
            for action: WebPage.NavigationAction,
            preferences: inout WebPage.NavigationPreferences
        ) async -> WKNavigationActionPolicy {
            return .allow
        }
    }
}
