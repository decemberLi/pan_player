//
//  VideoPlaybackViewModel.swift
//  SBSVideoExp
//
//  Created by Khaos Tian on 2/15/24.
//

import AVKit
import CoreVideo
import Foundation
import Metal
import RealityKit
import Observation
import KSPlayer

@Observable
final class VideoPlaybackViewModel {

    private let renderQueue = DispatchQueue(label: "render")

    private var mtlDevice: MTLDevice?
    private var commandQueue: MTLCommandQueue?
     private var metalLibrary: MTLLibrary?
    private var yuvToRgbComputePipeline: MTLComputePipelineState?
    private var yuv420PToRgbComputePipeline: MTLComputePipelineState?
    private var drawableQueue: TextureResource.DrawableQueue?

    private(set) var surfaceMaterial: ShaderGraphMaterial?
    private var textureResource: TextureResource?

    // FFmpeg 解码器（基于 MEPlayerItem）
//    private var decoder: FFmpegFrameDecoder?
    // 若仍需保留 AVPlayer 可设为弱引用，但此示例改为使用 FFmpeg
    weak var player: KSVideoPlayer.Coordinator?
    var url: URL?
    private var statusObservation: NSKeyValueObservation?
    private var displayLink: DisplayLink?
    private var textureCache: CVMetalTextureCache?

    init() {
        let device = MTLCreateSystemDefaultDevice()
        self.mtlDevice = device

        if let device {
            commandQueue = device.makeCommandQueue()
             // 准备 Metal 库与计算着色器
             do {
                 let library = try device.makeDefaultLibrary(bundle: .main)
                 self.metalLibrary = library
                if let function = library.makeFunction(name: "yuv420ToRGB") {
                    self.yuvToRgbComputePipeline = try device.makeComputePipelineState(function: function)
                }
                if let function420p = library.makeFunction(name: "yuv420PToRGB") {
                    self.yuv420PToRgbComputePipeline = try device.makeComputePipelineState(function: function420p)
                }
             } catch {
                 NSLog("Failed to create Metal library/pipeline: \(error.localizedDescription)")
             }
        }

        let res = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            mtlDevice!,
            nil,
            &textureCache
        )

        if res != kCVReturnSuccess {
            fatalError("Failed to create texture cache")
        }
       
    }

    @MainActor
    func loadShaderMaterial() async {
        var material = try! await ShaderGraphMaterial(
            named: "/Root/SBSMaterial",
            from: "SBSMaterial.usda"
        )

        /// Dummy data to create the texture resource
        let data = Data([0x00, 0x00, 0x00, 0xFF])

        let textureResource = try! await TextureResource(
            dimensions: .dimensions(width: 1, height: 1),
            format: .raw(pixelFormat: .bgra8Unorm),
            contents: .init(
                mipmapLevels: [
                    .mip(data: data, bytesPerRow: 4),
                ]
            )
        )

        self.textureResource = textureResource

        try! material.setParameter(
            name: "texture",
            value: .textureResource(textureResource)
        )

        self.surfaceMaterial = material
    }

    func update() {
        
        player?.onVideoFrame = { buffer in
            NSLog("FF width x height = \(CVPixelBufferGetWidth(buffer)) x \(CVPixelBufferGetHeight(buffer))")
            self.processVideoBuffer(buffer)
        }
        
        // 使用 FFmpeg 解码：传入 URL，准备好后启动 DisplayLink 拉帧
//        guard let url else { return }
//        let decoder = FFmpegFrameDecoder()
//        decoder.prepare(url: url) { _ in
//        }
//        self.decoder = decoder
//
//        // 刷新率使用保守默认 60fps（如需精确，可在上层传入或另行测量）
//        let displayLink = DisplayLink(frameRate: 60)
//        displayLink.handler = { [weak self] in
//            self?.handleDisplayLinkUpdate()
//        }
//        displayLink.start()
//        self.displayLink = displayLink
    }

    func stop() {
        player?.playerLayer?.pause()

        surfaceMaterial = nil
        textureResource = nil
        drawableQueue = nil
        statusObservation = nil
        displayLink = nil
        player = nil
    }

    // 不再使用 AVPlayerItemVideoOutput，改为从 FFmpeg 解码器取帧
    private func handleReadyToPlay(_ item: AVPlayerItem) { }

    private func handleDisplayLinkUpdate() {
//        renderQueue.async { [weak self] in
//            guard let self, let buffer = self.decoder?.nextPixelBuffer() else { return }
//            NSLog("FF width x height = \(CVPixelBufferGetWidth(buffer)) x \(CVPixelBufferGetHeight(buffer))")
//            self.processVideoBuffer(buffer)
//        }
    }

    private func processVideoBuffer(_ buffer: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)

        if let drawableQueue,
            drawableQueue.width == width,
           drawableQueue.height == height {
            renderWithDrawableQueue(drawableQueue, buffer: buffer)
        } else {
            do {
                let drawableQueue = try TextureResource.DrawableQueue(
                    TextureResource.DrawableQueue.Descriptor(
                        pixelFormat: .bgra8Unorm,
                        width: width,
                        height: height,
                        usage: [.renderTarget, .shaderRead, .shaderWrite],
                        mipmapsMode: .none
                    )
                )
                self.drawableQueue = drawableQueue

                DispatchQueue.main.async {[weak self] in
                    self?.textureResource!.replace(withDrawables: drawableQueue)
                }

                renderWithDrawableQueue(drawableQueue, buffer: buffer)
            } catch {
                NSLog("Failed to create drawable queue")
            }
        }
    }

    private func renderWithDrawableQueue(_ drawableQueue: TextureResource.DrawableQueue, buffer: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        // VideoTools.dumpPixelBufferAsImage(buffer) // 如需调试可开启
        let pixelFormat = CVPixelBufferGetPixelFormatType(buffer)

        // BGRA 直通路径
        if pixelFormat == kCVPixelFormatType_32BGRA {
            do {
                var bgraTextureRef: CVMetalTexture?
                let res = CVMetalTextureCacheCreateTextureFromImage(
                    kCFAllocatorDefault,
                    textureCache!,
                    buffer,
                    nil,
                    .bgra8Unorm,
                    width,
                    height,
                    0,
                    &bgraTextureRef
                )
                guard res == kCVReturnSuccess,
                      let bgraTextureRef,
                      let srcTexture = CVMetalTextureGetTexture(bgraTextureRef) else {
                    NSLog("Failed to create BGRA texture from CVPixelBuffer")
                    return
                }

                let drawable = try drawableQueue.nextDrawable()
                guard let commandBuffer = commandQueue?.makeCommandBuffer(),
                      let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { return }
                blitEncoder.copy(from: srcTexture, to: drawable.texture)
                blitEncoder.endEncoding()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                drawable.present()
            } catch {
                NSLog("BGRA blit failed: \(error)")
            }
            return
        }

        // NV12 (420f/420v) 计算着色器路径
        if pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ||
            pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
            guard let pipeline = yuvToRgbComputePipeline else {
                NSLog("Missing Metal device or compute pipeline for YUV->RGB")
                return
            }
            // 创建 luma 与 chroma 纹理
            var yTextureRef: CVMetalTexture?
            var uvTextureRef: CVMetalTexture?
            let yStatus = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                textureCache!,
                buffer,
                nil,
                .r8Unorm,
                width,
                height,
                0,
                &yTextureRef
            )
            let uvStatus = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                textureCache!,
                buffer,
                nil,
                .rg8Unorm,
                width / 2,
                height / 2,
                1,
                &uvTextureRef
            )

            guard yStatus == kCVReturnSuccess,
                  uvStatus == kCVReturnSuccess,
                  let yTextureRef,
                  let uvTextureRef,
                  let yTexture = CVMetalTextureGetTexture(yTextureRef),
                  let uvTexture = CVMetalTextureGetTexture(uvTextureRef) else {
                NSLog("Failed to create Y/UV textures from NV12 pixel buffer")
                return
            }

            do {
                let drawable = try drawableQueue.nextDrawable()
                guard let commandBuffer = commandQueue?.makeCommandBuffer(),
                      let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                    return
                }
                computeEncoder.setComputePipelineState(pipeline)
                computeEncoder.setTexture(yTexture, index: 0)
                computeEncoder.setTexture(uvTexture, index: 1)

                // 传尺寸 (使用 width-1/height-1 配合 kernel 的范围判断)
                var size: [UInt32] = [UInt32(max(width - 1, 0)), UInt32(max(height - 1, 0))]
                computeEncoder.setBytes(&size, length: MemoryLayout<UInt32>.size * 2, index: 2)
                computeEncoder.setTexture(drawable.texture, index: 3)

                // 调度线程
                let w = pipeline.threadExecutionWidth
                let h = max(1, pipeline.maxTotalThreadsPerThreadgroup / w)
                let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
                let threadgroupsPerGrid = MTLSize(width: (width + w - 1) / w,
                                                  height: (height + h - 1) / h,
                                                  depth: 1)
                computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                computeEncoder.endEncoding()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                drawable.present()
            } catch {
                NSLog("NV12 compute render failed: \(error)")
            }
            return
        }

        // I420/YUV420Planar 三平面路径（常量值 2033463856，'y420'）
        if pixelFormat == kCVPixelFormatType_420YpCbCr8PlanarFullRange ||
            pixelFormat == kCVPixelFormatType_420YpCbCr8Planar {
            guard let pipeline = yuv420PToRgbComputePipeline else {
                NSLog("Missing compute pipeline for YUV420P->RGB")
                return
            }
            // 三平面：plane 0 -> Y, plane 1 -> U, plane 2 -> V
            var yTexRef: CVMetalTexture?
            var uTexRef: CVMetalTexture?
            var vTexRef: CVMetalTexture?
            let yStatus = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                textureCache!,
                buffer,
                nil,
                .r8Unorm,
                width,
                height,
                0,
                &yTexRef
            )
            let uStatus = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                textureCache!,
                buffer,
                nil,
                .r8Unorm,
                width / 2,
                height / 2,
                1,
                &uTexRef
            )
            let vStatus = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                textureCache!,
                buffer,
                nil,
                .r8Unorm,
                width / 2,
                height / 2,
                2,
                &vTexRef
            )

            guard yStatus == kCVReturnSuccess,
                  uStatus == kCVReturnSuccess,
                  vStatus == kCVReturnSuccess,
                  let yTexRef,
                  let uTexRef,
                  let vTexRef,
                  let yTexture = CVMetalTextureGetTexture(yTexRef),
                  let uTexture = CVMetalTextureGetTexture(uTexRef),
                  let vTexture = CVMetalTextureGetTexture(vTexRef) else {
                NSLog("Failed to create Y/U/V textures from I420 pixel buffer")
                return
            }

            do {
                let drawable = try drawableQueue.nextDrawable()
                guard let commandBuffer = commandQueue?.makeCommandBuffer(),
                      let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                    return
                }
                computeEncoder.setComputePipelineState(pipeline)
                computeEncoder.setTexture(yTexture, index: 0)
                computeEncoder.setTexture(uTexture, index: 1)
                computeEncoder.setTexture(vTexture, index: 2)

                var size: [UInt32] = [UInt32(max(width - 1, 0)), UInt32(max(height - 1, 0))]
                computeEncoder.setBytes(&size, length: MemoryLayout<UInt32>.size * 2, index: 2)
                computeEncoder.setTexture(drawable.texture, index: 3)

                let w = pipeline.threadExecutionWidth
                let h = max(1, pipeline.maxTotalThreadsPerThreadgroup / w)
                let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
                let threadgroupsPerGrid = MTLSize(width: (width + w - 1) / w,
                                                  height: (height + h - 1) / h,
                                                  depth: 1)
                computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                computeEncoder.endEncoding()
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                drawable.present()
            } catch {
                NSLog("YUV420P compute render failed: \(error)")
            }
            return
        }

        NSLog("Unsupported CVPixelBuffer pixel format: \(pixelFormat)")
    }

    private class DisplayLink: NSObject {

        private let frameRate: Float

        private var internalDisplayLink: CADisplayLink?
        var handler: (() -> Void)?

        init(frameRate: Float) {
            self.frameRate = frameRate
            super.init()
        }

        deinit {
            stop()
        }

        func start() {
            internalDisplayLink?.invalidate()

            internalDisplayLink = CADisplayLink(
                target: self,
                selector: #selector(displayLinkFired)
            )
            internalDisplayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: frameRate, maximum: frameRate)
            internalDisplayLink?.add(to: .main, forMode: .common)
        }

        func stop() {
            internalDisplayLink?.invalidate()
            internalDisplayLink = nil
        }

        @objc
        private func displayLinkFired() {
            handler?()
        }
    }
}
