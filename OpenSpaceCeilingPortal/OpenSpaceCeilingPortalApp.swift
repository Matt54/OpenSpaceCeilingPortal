//
//  OpenSpaceCeilingPortalApp.swift
//  OpenSpaceCeilingPortal
//
//  Created by Matt Pfeiffer on 10/12/24.
//

import SwiftUI

@main
struct OpenSpaceCeilingPortalApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            OuterSpaceCeilingPortalView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
