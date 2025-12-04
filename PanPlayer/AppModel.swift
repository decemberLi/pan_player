//
//  AppModel.swift
//  PanPlayer
//
//  Created by dec on 2025/7/25.
//

import SwiftUI
import AVFoundation
import KSPlayer

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    
    // 视频播放视图模型
    var videoPlaybackViewModel = VideoPlaybackViewModel()
    var player = VideoPlayer()
    
    var streamModel : StreamModel?       
    
    init() {
        KSOptions.secondPlayerType = KSMEPlayer.self
        // 启动本地HTTP代理，用于原画下载链接的边下边播
        LocalHTTPProxy.shared.start()
        Task {
          await  videoPlaybackViewModel.loadShaderMaterial()
        }
        
        // 监听app状态变化
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            LocalHTTPProxy.shared.start()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            LocalHTTPProxy.shared.stop()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 选择视频文件
    func selectVideo(url: URL) {
        print("[AppModel] selectVideo url=\(url.absoluteString)")
        let model = StreamModel(title: "video", details: "", url: url)
        streamModel = model
        player.openStream(model)
        videoPlaybackViewModel.player = player.player
        videoPlaybackViewModel.update()
    }
    
    
    // 播放视频
    func playVideo() {
        print("[AppModel] playVideo")
        player.play()
       
    }
    
    // 暂停视频
    func pauseVideo() {
        print("[AppModel] pauseVideo")
        player.pause()
    }
    
    // 停止视频
    func stopVideo() {
        print("[AppModel] stopVideo")
        player.stop()
    }
    
    // 清除选中的视频
    func clearVideo() {
        player.stop()
    }

}
