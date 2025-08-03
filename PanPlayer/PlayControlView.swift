//
//  PlayControlView.swift
//  PanPlayer
//
//  Created by dec on 2025/7/26.
//
import SwiftUI

struct PlayControlView : View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismissWindow) private var dissmissWindow
    @Environment(\.openWindow) private var openWidnow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    private func formatTime(_ time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack {
            // 时间显示
            HStack {
                Text(formatTime(appModel.currentVideoTime))
                    .foregroundColor(.white)
                    .font(.caption)
                Text("/")
                Text(formatTime(appModel.videoDuration))
                    .foregroundColor(.white)
                    .font(.caption)
            }
            HStack(spacing: 20) {
                // 播放/暂停按钮
                Button(action: {
                    if self.appModel.isVideoPlaying {
                        self.appModel.pauseVideo()
                    } else {
                        self.appModel.playVideo()
                    }
                }) {
                    Image(systemName: appModel.isVideoPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 滑动条
                Slider(
                    value: Binding(
                        get: { self.appModel.currentVideoTime },
                        set: { self.appModel.seekToTime($0) }
                    ),
                    in: 0...max(0.1, self.appModel.videoDuration),
                    onEditingChanged: { editing in
                        // 可以在这里添加编辑状态的处理
                    }
                )
                .frame(maxWidth: 300)
                
                // 关闭按钮
                Button(action: {
                    self.appModel.clearVideo()
                    self.appModel.controlWindowIsShow = false
                    Task {
                        openWidnow(id: WindowIDs.mainWindow)
                        dissmissWindow(id: WindowIDs.playControlWindow)
                        await dismissImmersiveSpace()
                        
                    }
                    
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        
    }
}
