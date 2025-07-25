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
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: 20) {
            
            // 文件选择按钮
            Button(action: {
                showingFilePicker = true
            }) {
                Label("选择180度VR视频文件", systemImage: "folder")
                    .font(.title2)
                    .padding()
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // 视频播放器（2D预览）
            if let player = appModel.player {
                VideoPlayer(player: player)
                    .cornerRadius(10)
            }
            
            // VR模式按钮
            ToggleImmersiveSpaceButton()
                .disabled(appModel.selectedVideoURL == nil)
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
                }
            case .failure(let error):
                print("文件选择错误: \(error)")
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
