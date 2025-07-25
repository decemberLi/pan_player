//
//  ImmersiveView.swift
//  PanPlayer
//
//  Created by dec on 2025/7/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVKit

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var videoEntity: ModelEntity?
    @State private var playerLayer: AVPlayerLayer?
    
    var body: some View {
        RealityView { content in
            // 创建180度VR视频播放器
            if let player = appModel.player {
                setup180VRVideoPlayer(player: player, content: content)
            }
        }
        .onAppear {
            // 设置VR空间状态为打开
            appModel.immersiveSpaceState = .open
        }
        .onDisappear {
            // 设置VR空间状态为关闭
            appModel.immersiveSpaceState = .closed
        }
    }
    
    private func setup180VRVideoPlayer(player: AVPlayer, content: RealityViewContent) {
        // 创建180度VR视频播放器 - 使用半球形状
        let hemisphereMesh = createHemisphereMesh(radius: 20)
        
        // 创建视频材质
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        // 创建视频实体
        let videoEntity = ModelEntity(mesh: hemisphereMesh, materials: [videoMaterial])
        
        // 旋转半球让画面面向用户前方（绕Y轴旋转180度）
        videoEntity.transform.rotation = simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 1, 0))
        videoEntity.position = .init(x: 0, y: 0, z: -10)
        
        // 添加到场景
        content.add(videoEntity)
        
        
        
        // 保存引用
        self.videoEntity = videoEntity
        Task {
          try? await  Task.sleep(nanoseconds: 1000000000)//1秒
            
            // 开始播放
            player.play()
            appModel.isVideoPlaying = true
        }
    }
    
    // 创建半球网格（只有前180度）
    private func createHemisphereMesh(radius: Float) -> MeshResource {
        var descriptor = MeshDescriptor()
        
        let segments = 40  // 水平分段数
        let rings = 20     // 垂直分段数
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var triangleIndices: [UInt32] = []
        
        // 生成前方180度半球的顶点
        for ring in 0...rings {
            // 垂直角度：从0到π（上到下完整半圆）
            let phi = Float.pi * Float(ring) / Float(rings)
            let y = cos(phi) * radius
            let ringRadius = sin(phi) * radius
            
            for segment in 0...segments {
                // 水平角度：-π/2到π/2（前方180度）
                let theta = Float.pi * Float(segment) / Float(segments) - Float.pi/2
                let x = sin(theta) * ringRadius
                let z = cos(theta) * ringRadius
                
                let position = SIMD3<Float>(x, y, z)
                positions.append(position)
                
                // 法向量指向球心（因为我们在内部观看）
                let normal = normalize(-position)
                normals.append(normal)
                
                // 纹理坐标（只使用左半部分纹理，适配side-by-side格式的180度VR视频）
                let u = Float(segment) / Float(segments) * 0.5  // 只使用左半部分
                let v = 1.0 - Float(ring) / Float(rings)
                textureCoordinates.append(SIMD2<Float>(u, v))
            }
        }
        
        // 生成三角形索引（调整顺序使面朝向内部）
        for ring in 0..<rings {
            for segment in 0..<segments {
                let current = UInt32(ring * (segments + 1) + segment)
                let next = current + UInt32(segments + 1)
                
                // 第一个三角形（调整顺序使面朝向内部）
                triangleIndices.append(current)
                triangleIndices.append(current + 1)
                triangleIndices.append(next)
                
                // 第二个三角形（调整顺序使面朝向内部）
                triangleIndices.append(current + 1)
                triangleIndices.append(next + 1)
                triangleIndices.append(next)
            }
        }
        
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(textureCoordinates)
        descriptor.primitives = .triangles(triangleIndices)
        
        return try! MeshResource.generate(from: [descriptor])
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
