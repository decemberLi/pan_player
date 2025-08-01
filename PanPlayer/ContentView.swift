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
import Toasts

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.presentToast) var presentToast
    
    @State private var showingFilePicker = false
    @State private var showPlayer = false
    @State private var showLoginAlert = false
    @State private var showWebView = false
    
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
                        // 导航到FileListView115
                        pushWindow(id: "fileList", content: {
                            FileListView115(cid: nil)
                                .environment(appModel)
                        })
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
                        showWebView = true
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
            let url = TokenManager115.shared.requestWebURL
            WebViewContainer(url: url) { params in
                // 处理检测到的URL
                self.showWebView = false
                print("检测到的参数: \(params)")
                let code = params["code"]
                let toast = ToastValue(
                    icon: Image(systemName: "bell"),
                    message: "获取token失败"
                )
                guard let code else{
                    presentToast(toast)
                    return
                }
                Task {
                    do {
                        try await TokenManager115.shared.getToken(code: code)
                    } catch {
                        presentToast(toast)
                    }
                }
            }
        }
    }
    
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
