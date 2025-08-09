import SwiftUI
import AVKit
import KSPlayer

struct AVPlayerViewControllerWrapper: UIViewRepresentable {
    
    let url: URL
    var showVR : (()->Void)?
    
    func makeUIView(context: Context) -> IOSVideoPlayerView {
      let player = IOSVideoPlayerView()
        let options = KSOptions()
        options.display = .vr
        player.set(url: url, options: options)
        return player
    }
    
    func updateUIView(_ uiView: IOSVideoPlayerView, context: Context) {
        //        uiViewController.player = player
    }
}

struct PlayView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dimiss
    
    
    var body: some View {
        let url = appModel.streamModel?.url
        Group {
            if let url {
                let options = {
                    let op = KSOptions()
                    op.display = .vr
                    return op
                }()
                KSVideoPlayer(coordinator: appModel.player.player, url: url, options: options)
            }
        }
        
        .onDisappear {
            appModel.pauseVideo()
        }
        .ignoresSafeArea()
    }
}
