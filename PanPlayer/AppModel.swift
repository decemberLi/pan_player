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
        Task {
          await  videoPlaybackViewModel.loadShaderMaterial()
        }
    }
    
    // 选择视频文件
    func selectVideo(url: URL) {
        let model = StreamModel(title: "video", details: "", url: url)
        streamModel = model
        player.openStream(model)
        videoPlaybackViewModel.player = player.player
        videoPlaybackViewModel.update()
    }
    
    
    // 播放视频
    func playVideo() {
        player.play()
       
    }
    
    // 暂停视频
    func pauseVideo() {
        player.pause()
    }
    
    // 停止视频
    func stopVideo() {
        player.stop()
    }
    
    // 清除选中的视频
    func clearVideo() {
        player.stop()
    }

}
