//
//  ContentView.swift
//  OCKVisionSample
//
//  Created by Corey Baker on 5/7/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
