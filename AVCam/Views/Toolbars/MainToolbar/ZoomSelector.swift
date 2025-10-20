//
//  ZoomSelector.swift
//  AVCam
//
//  Created by Austin Ouyang on 10/15/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import PhotosUI


/// A purely visual zoom selector with fixed options 0.5 and 1.0.
/// - Interaction: Horizontal swipe or tap to toggle.
/// - Styling:
///   - Selected: yellow font, opaque gray circle background, 5pt padding around text.
///   - Unselected: white font.
/// - Behavior: Selected item is always centered; the other sits left or right.
struct ZoomSelector<CameraModel: Camera>: View {
    // Fixed options.
    private let options: [CGFloat] = [0.5, 1.0]
    // Selected index; default to 1.0 (index 1).
    @State private var selectedIndex: Int = 1
    
    @State var camera: CameraModel
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(options.indices, id: \.self) { idx in
                item(for: options[idx], isSelected: selectedIndex == idx)
                    .tag(idx)
                    // Provide a consistent size so the selected item remains centered.
                    .frame(width: 80, height: 32)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        // Constrain overall size; leave some room for swipe.
        .frame(width: 120, height: 70)
        // Toggle on tap for quick switching.
        .onTapGesture {
            withAnimation(.easeInOut) {
                selectedIndex = selectedIndex == 0 ? 1 : 0
            }
        }
        // Optional: haptic feedback when selection changes (purely visual otherwise).
        .onChange(of: selectedIndex) { _, _ in
            // No integration with camera; visualization only.
            Task {
                var deviceName: String {
                    options[selectedIndex] >= 1.0 ? "Back Camera" : "Back Ultra Wide Camera"
                }
                var zoom: CGFloat {
                    options[selectedIndex] >= 1.0 ? options[selectedIndex] : options[selectedIndex]*2.0
                }
                await camera.selectVideoDevice(to: deviceName)
                await camera.setZoom(zoom)
            }
        }
    }
    
    @ViewBuilder
    private func item(for factor: CGFloat, isSelected: Bool) -> some View {
        let text = factor == 1.0 ? "1x" : "0.5x"
        if isSelected {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.yellow)
                .padding(10)
                .background(
                    Circle().fill(.regularMaterial.opacity(0.8))
                )
                .accessibilityLabel("Selected zoom \(text)x")
        } else {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .accessibilityLabel("Zoom \(text)x")
        }
    }
}
