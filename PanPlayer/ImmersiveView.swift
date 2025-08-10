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
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State private var rootEntity: Entity?

    private let headTracker = HeadTracker()
    
    var body: some View {
        RealityView { content,attachments in
            let root = Entity()
            root.name = "root"
            root.position = [0.0,1.2,0.0]
            content.add(root)
            rootEntity = root
            // 创建180度VR视频播放器
            let videoPlayer = appModel.player
            let player = videoPlayer.player
            let videoEntity = setup180VRVideoPlayer()
            root.addChild(videoEntity)
            
            
            // Setup ControlPanel as a floating window within the immersive scene
            if let controlPanel = attachments.entity(for: "ControlPanel") {
                let config = Config.shared
                controlPanel.name = "ControlPanel"
                controlPanel.position = [0, config.controlPanelVerticalOffset, -config.controlPanelHorizontalOffset]
                controlPanel.orientation = simd_quatf(angle: -config.controlPanelTilt * .pi/180, axis: [1, 0, 0])
                root.addChild(controlPanel)
            }
            
            let collisionShape: ShapeResource =
                .generateBox(width: 100, height: 100, depth: 1)
                .offsetBy(translation: [0.0, 0.0, -5.0])
            
            let tapEntity = Config.shared.tapCatcherShowDebug ?
            ModelEntity(
                mesh: MeshResource(shape: collisionShape),
                materials: [UnlitMaterial(color: .red)]
            ) : Entity()
            
            tapEntity.name = "TapCatcher"
            tapEntity.components.set(CollisionComponent(shapes: [collisionShape], mode: .trigger, filter: .default))
            tapEntity.components.set(InputTargetComponent())
            root.addChild(tapEntity)
            
        } update: { content, attachments in
            let videoPlayer = appModel.player
            if let progressView = attachments.entity(for: "ProgressView") {
                progressView.isEnabled = videoPlayer.buffering || videoPlayer.loading
            }
        } placeholder: {
            ProgressView()
        } attachments: {
            
            Attachment(id: "ControlPanel") {
                ControlPanel(closeAction: {
                    Task {
                        await dismissImmersiveSpace()
                         dismissWindow(id: WindowIDs.emptyWindow)
                    }
                } )
            }
            Attachment(id: "ProgressView") {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                // 加载surfaceMaterial
//                await appModel.videoPlaybackViewModel.loadShaderMaterial()
                
                // 等待1秒
                try? await Task.sleep(nanoseconds: 1000000000)
                
                // 开始播放
                appModel.playVideo()
            }
        }
        .onDisappear {
            // 设置VR空间状态为关闭
            appModel.player.stop()
            headTracker.stop()
        }
        .gesture(TapGesture()
            .targetedToAnyEntity()
            .onEnded { event in
                let videoPlayer = appModel.player
                videoPlayer.toggleControlPanel()
            }
        )
       
        
    }
    
    private func setup180VRVideoPlayer() -> Entity {
        // 创建180度VR视频播放器 - 使用半球形状
//        let hemisphereMesh = createHemisphereMesh(radius: 1.5)
        let (hemisphereMesh,transform) = VideoTools.makeVideoMesh()
        
        // 创建视频实体
        let videoEntity = ModelEntity(mesh: hemisphereMesh, materials: [appModel.videoPlaybackViewModel.surfaceMaterial!])
        
        videoEntity.transform = transform
        
        return videoEntity
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
                   let u = Float(segment) / Float(segments) 
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
