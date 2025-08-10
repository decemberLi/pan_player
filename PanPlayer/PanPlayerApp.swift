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
        
        WindowGroup(id:WindowIDs.emptyWindow) {
            Rectangle()
                .fill(.clear)
                .frame(width: 0, height: 0)
        }
        .persistentSystemOverlays(.hidden)
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        ImmersiveSpace(id: WindowIDs.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
