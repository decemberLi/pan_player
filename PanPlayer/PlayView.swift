import SwiftUI
import AVKit

struct AVPlayerViewControllerWrapper: UIViewControllerRepresentable {
    let player: AVPlayer?
    var showVR : (()->Void)?
    static var controller = AVPlayerViewController()
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = Self.controller
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
        
    }
}

struct PlayView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.dismiss) private var dimiss
    
    
    var body: some View {
        AVPlayerViewControllerWrapper(player: appModel.player,showVR: {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                    case .open:
                        appModel.immersiveSpaceState = .inTransition
                        await dismissImmersiveSpace()
                        // Don't set immersiveSpaceState to .closed because there
                        // are multiple paths to ImmersiveView.onDisappear().
                        // Only set .closed in ImmersiveView.onDisappear().

                    case .closed:
                        
                        appModel.immersiveSpaceState = .inTransition
                        switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                            case .opened:
                                // Don't set immersiveSpaceState to .open because there
                                // may be multiple paths to ImmersiveView.onAppear().
                                // Only set .open in ImmersiveView.onAppear().
                                break

                            case .userCancelled, .error:
                                // On error, we need to mark the immersive space
                                // as closed because it failed to open.
                                fallthrough
                            @unknown default:
                                // On unknown response, assume space did not open.
                                appModel.immersiveSpaceState = .closed
                        }
                        dimiss()
                        dismissWindow(id:"mainWindow")
                        pushWindow(id: "playControlWindow")
                        appModel.controlWindowIsShow = true

                    case .inTransition:
                        // This case should not ever happen because button is disabled for this case.
                        break
                }
            }
        })
            .ignoresSafeArea()
    }
}
