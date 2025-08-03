//
//  PanPlayerApp.swift
//  PanPlayer
//
//  Created by dec on 2025/7/25.
//

import SwiftUI
import Toasts

@main
struct PanPlayerApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup(id: WindowIDs.mainWindow) {
            MainView()
                .environment(appModel)
                .installToast()
        }
        
        WindowGroup(id: WindowIDs.playControlWindow) {
            PlayControlView()
                .environment(appModel)
        }
        .defaultSize(width: 600, height: 300)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
