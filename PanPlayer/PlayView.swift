import SwiftUI
import AVKit

struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
    let player: AVPlayer?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        let infoCircle = UIImage(systemName: "eye")
        let showMoreInfo = UIAction(title: "Show VR", image: infoCircle) { action in
            // Navigate to a screen to display more information.
        }
        // Append the action to the array.
        controller.contextualActions = [showMoreInfo]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

struct PlayView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        AVPlayerViewControllerWrapper(player: appModel.player)
            .ignoresSafeArea()
    }
}
