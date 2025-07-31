//
//  ContentView.swift
//  PanPlayer
//
//  Created by dec on 2025/7/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.pushWindow) private var pushWindow
    @State private var showingFilePicker = false
    @State private var showPlayer = false
    @State private var showLoginAlert = false
    @State private var showWebView = false
    @State private var webViewUrl: URL? = nil
    @State private var detectedUrl: String? = nil

    var body: some View {
        Grid(horizontalSpacing: 30, verticalSpacing: 30) {
            GridRow {
                // 文件选择按钮
                Button(action: {
                    showingFilePicker = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("选择视频文件")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // 115网盘按钮
                Button(action: {
                    // 检查UserDefaults中是否包含115token
                    if UserDefaults.standard.string(forKey: "115token") == nil {
                        showLoginAlert = true
                    } else {
                        // TODO: 已登录状态下的操作
                    }
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("115网盘")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .alert("需要登录", isPresented: $showLoginAlert) {
                    Button("确定") {
                        // 跳转到115登录页面
                        if let url = URL(string: "https://passportapi.115.com/open/authorize?client_id=100197637&redirect_uri=https://vrplayer.space&response_type=code&state=123456") {
                            webViewUrl = url
                            showWebView = true
                        }
                    }
                    Button("取消", role: .cancel) { }
                } message: {
                    Text("检测到您尚未登录115网盘，点击确定前往登录页面。")
                }
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.movie, .video],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appModel.selectVideo(url: url)
                    showPlayer = true
                }
            case .failure(let error):
                print("文件选择错误: \(error)")
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            PlayView()
        }
        .fullScreenCover(isPresented: $showWebView) {
            if let url = webViewUrl {
                WebViewContainer(url: url) { detectedUrl in
                    // 处理检测到的URL
                    self.detectedUrl = detectedUrl
                    self.showWebView = false
                    print("检测到的URL: \(detectedUrl)")
                    // 这里可以添加进一步处理URL的逻辑
                }
            }
        }
    }
    
    // 格式化时间显示
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
