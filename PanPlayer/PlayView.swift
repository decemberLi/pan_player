import SwiftUI
import AVKit

struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
    let player: AVPlayer?
    var showVR : (()->Void)?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        let infoCircle = UIImage(systemName: "eye")
        let showMoreInfo = UIAction(title: "Show VR", image: infoCircle) { action in
            showVR?()
        }
        // Append the action to the array.
        controller.contextualActions = [showMoreInfo]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
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
        AVPlayerViewControllerWrapper(player: appModel.player.player,showVR: {
            Task { @MainActor in
                await openImmersiveSpace(id: WindowIDs.immersiveSpaceID)
                dimiss()
                dismissWindow(id: WindowIDs.mainWindow)
            }
        })
        .ignoresSafeArea()
    }
}
