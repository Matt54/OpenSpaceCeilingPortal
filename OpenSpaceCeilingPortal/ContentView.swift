//
//  ContentView.swift
//  OpenSpaceCeilingPortal
//
//  Created by Matt Pfeiffer on 10/12/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Open Space Ceiling Portal")
            ToggleImmersiveSpaceButton()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
