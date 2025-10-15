/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays controls to capture, switch cameras, and view the last captured media item.
*/

import SwiftUI
import PhotosUI

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar<CameraModel: Camera>: PlatformView {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    var body: some View {
        VStack {
            ZoomSelector()
            HStack {
                ThumbnailButton(camera: camera)
                // Hide the thumbnail button when a person interacts with capture controls.
                    .opacity(camera.prefersMinimizedUI ? 0 : 1)
                Spacer()
                VStack(spacing: 8) {
                    CaptureButton(camera: camera)
                }
                Spacer()
                SwitchCameraButton(camera: camera)
                // Hide the camera selection when a person interacts with capture controls.
                    .opacity(camera.prefersMinimizedUI ? 0 : 1)
            }
            .foregroundColor(.white)
            .font(.system(size: 24))
            .frame(width: width, height: height)
            .padding([.leading, .trailing])
        }
    }
    
    var width: CGFloat? { isRegularSize ? 250 : nil }
    var height: CGFloat? { 80 }
}

/// A purely visual zoom selector with fixed options 0.5 and 1.0.
/// - Interaction: Horizontal swipe or tap to toggle.
/// - Styling:
///   - Selected: yellow font, opaque gray circle background, 5pt padding around text.
///   - Unselected: white font.
/// - Behavior: Selected item is always centered; the other sits left or right.
private struct ZoomSelector: View {
    // Fixed options.
    private let options: [CGFloat] = [0.5, 1.0]
    // Selected index; default to 1.0 (index 1).
    @State private var selectedIndex: Int = 1
    
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
                    Circle().fill(Color.gray.opacity(0.9))
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

#Preview {
    Group {
        MainToolbar(camera: PreviewCameraModel())
    }
}
