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
                    // TODO: 添加115网盘功能
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
