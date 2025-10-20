//
//  Home.swift
//  AVCam
//
//  Created by Austin Ouyang on 10/13/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    // Simulator doesn't support the AVFoundation capture APIs. Use the preview camera when running in Simulator.
    @State private var camera = CameraModel()
       
    // Selections (lifted here if you want to persist or share them).
    @State private var selectedResolutionLabel: String = "1080p"
    @State private var selectedFPSLabel: String = "240FPS"
    
    // An indication of the scene's operational state.
    @Environment(\.scenePhase) var scenePhase
 
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    NavigationLink("Record", destination:
                                    CameraView(camera: camera)
                        .statusBarHidden(true)
                        .task {
                            // Start the capture pipeline.
                            await camera.start()
                        }
                                   // Monitor the scene phase. Synchronize the persistent state when
                                   // the camera is running and the app becomes active.
                        .onChange(of: scenePhase) { _, newPhase in
                            guard camera.status == .running, newPhase == .active else { return }
                            Task { @MainActor in
                                await camera.syncState()
                            }
                        }
                    )
                    NavigationLink("Library", destination: LibraryView())
                }
                .navigationTitle("Kynetik")
            }
        }
    }
}
