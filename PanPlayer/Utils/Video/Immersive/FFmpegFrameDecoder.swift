//
//  FFmpegFrameDecoder.swift
//  Example
//
//  基于 KSPlayer-FFmpeg-Core 的 MEPlayerItem 提供帧拉取能力
//

import AVFoundation
import KSPlayer
import VideoToolbox
import ImageIO
import UniformTypeIdentifiers

final class FFmpegFrameDecoder {
    private var options = KSOptions()
    private var item: MEPlayerItem?
    private var didDumpOneFrame = false

    func prepare(url: URL, configure: ((KSOptions) -> Void)? = nil) {
        let opts = KSOptions()
        // 合理的默认项：启用硬解；关闭自研异步硬解，避免部分流时间戳异常
        opts.hardwareDecode = true
        opts.asynchronousDecompression = false
        opts.isAccurateSeek = false
        configure?(opts)
        options = opts
        item = MEPlayerItem(url: url, options: opts)
        item?.prepareToPlay()
    }

    func shutdown() {
        item?.shutdown()
        item = nil
    }

    // 拉取下一帧像素，若存在则返回 CVPixelBuffer
    func nextPixelBuffer(force: Bool = false) -> CVPixelBuffer? {
        guard let frame = item?.getVideoOutputRender(force: force), let pixel = frame.corePixelBuffer?.cvPixelBuffer else {
            return nil
        }
        
        item?.setVideo(time: frame.cmtime, position: frame.position)
        return pixel
    }

    
}


