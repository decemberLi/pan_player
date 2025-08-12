//
//  ContentView.swift
//  PanPlayer
//
//  Created by dec on 2025/7/25.
//

import SwiftUI
import RealityKit
import AVKit
import UniformTypeIdentifiers
import Toasts
import PhotosUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.presentToast) var presentToast
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.openWindow) var openWindow
    
    @State private var showingFilePicker = false
    @State private var showPlayer = false
    @State private var showLoginAlert = false
    @State private var showWebView = false
    @State private var path = NavigationPath()
    @State private var showPhotosPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack(path: $path) {
            Grid(horizontalSpacing: 30, verticalSpacing: 30) {
                GridRow {
                    // 相册视频按钮
                    Button(action: {
                        showPhotosPicker = true
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text("相册视频")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
                        if TokenManager115.shared.token == nil {
                            showLoginAlert = true
                        } else {
                            // 导航到FileListView115
                            path.append("root")
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
                            #if DEBUG
                            //https://vrplayer.space/?code=26f2ad4e36f385372e6310e52c42832d&state=123456
                            // Task {
                            //     do {
                            //         try await TokenManager115.shared.getToken(code: "26f2ad4e36f385372e6310e52c42832d", stateString: "123456")
                            //     }catch{
                                    
                            //     }
                            // }
                            // return
                            #endif
                            showWebView = true
                        }
                        Button("取消", role: .cancel) { }
                    } message: {
                        Text("检测到您尚未登录115网盘，点击确定前往登录页面。")
                    }

                   
                }
            }
            .navigationDestination(for: String.self) { cid in
                FileListView115(currentDir: nil)
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.movie, .video],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                
                if let url = urls.first {
                   _ = url.startAccessingSecurityScopedResource()
                    appModel.selectVideo(url: url)
                    showPlayer = true
                }
            case .failure(let error):
                print("文件选择错误: \(error)")
            }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoPickerItem, matching: .videos)
        .onChange(of: photoPickerItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                do {
                    if let movie = try await item.loadTransferable(type: SpatialVideo.self) {
                        switch movie.status {
                        case .ready:
                            appModel.selectVideo(url: movie.url)
                            showPlayer = true
                        case .failed:
                            print("相册视频解析失败")
                        }
                    }
                } catch {
                    print("从相册加载视频失败: \(error)")
                }
                // 重置，便于下一次选择
                photoPickerItem = nil
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
                let state = params["state"]
                let toast = ToastValue(
                    icon: Image(systemName: "bell"),
                    message: "获取token失败"
                )
                guard let code,let state else{
                    presentToast(toast)
                    return
                }
                Task {
                    do {
                        try await TokenManager115.shared.getToken(code: code,stateString: state)
                    } catch {
                        presentToast(toast)
                    }
                }
            }
        }
        .onAppear {
            #if DEBUG
            /*
             {
                 "access_token" = "bcb18.28fee7215b91dfbc057cc19b185ee9ea.034c565223d9928bdc011811ff898d6c68bb7b1afeccc1555ccea3612bb9e622";
                 "expires_in" = 7200;
                 "refresh_token" = "bcb18.187b9c4a4576dc5f031d0b6d38e851ee3977040a71a2cccffadfb9c2376504e1.151a8a8f810c1d3174959ca1c12e1e6e639205ba0d2c1b49ae0197adade24346";
             }
             */
//              let tokenJsonString = """
//              {"expires_in":7200,"refresh_token":"bcb18.69dcbebf7dc4bffc839bc5d4f9c46f0a68cf7837d6ba3e0ee0991f9e313d8bb4.c06b68fc7ec7c85fece054e235aaf9b54d280f67a0b12e33a02c320882ac5d70","access_token":"bcb18.c697899cacca8aca9e53e9558814c30d.4b377020b3f961f2b48579465db46592a0407bb56cf42ad8657b0814289e5c02"}
//              """
//              UserDefaults.standard.set(tokenJsonString, forKey: "115token")
//             let date = Date()
//             UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "115lastUpdateTime")
//            Task {
//              try? await  TokenManager115.shared.refreshToken()
//            }
            #endif
        }
    }
    
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
