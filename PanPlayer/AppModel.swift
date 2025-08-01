//
//  AppModel.swift
//  PanPlayer
//
//  Created by dec on 2025/7/25.
//

import SwiftUI
import AVFoundation

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // 视频相关状态
    var selectedVideoURL: URL?
    var isVideoPlaying: Bool = false
    var player: AVPlayer? {
        didSet {
            oldValue?.pause()
        }
    }
    var currentVideoTime: Double = 0
    var videoDuration: Double = 0
    var controlWindowIsShow: Bool = false
    
    // 选择视频文件
    func selectVideo(url: URL) {
        selectedVideoURL = url
        player = AVPlayer(url: url)
        // 获取视频时长
        let asset = AVURLAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                videoDuration = CMTimeGetSeconds(duration)
            } catch {
                print("获取视频时长失败: \(error)")
            }
        }
        
        // 监听播放时间
        setupTimeObserver()
    }
    
    // 设置时间观察器
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentVideoTime = CMTimeGetSeconds(time)
        }
    }
    
    // 播放视频
    func playVideo() {
        player?.play()
        isVideoPlaying = true
    }
    
    // 暂停视频
    func pauseVideo() {
        player?.pause()
        isVideoPlaying = false
    }
    
    // 停止视频
    func stopVideo() {
        player?.pause()
        player?.seek(to: .zero)
        isVideoPlaying = false
        currentVideoTime = 0
    }
    
    // 跳转到指定时间
    func seekToTime(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    // 清除选中的视频
    func clearVideo() {
        player?.pause()
        player = nil
        selectedVideoURL = nil
        isVideoPlaying = false
        currentVideoTime = 0
        videoDuration = 0
    }

}
