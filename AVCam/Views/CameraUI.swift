/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the main camera user interface.
*/

import SwiftUI
import AVFoundation
import UIKit

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera>: PlatformView {

    @State var camera: CameraModel
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Capture the current UIScreen from the view context.
    @State private var currentScreen: UIScreen?
    
    var body: some View {
        Group {
            if isRegularSize {
                regularUI
            } else {
                compactUI
            }
        }
        // Install a tiny helper that updates currentScreen from the active window.
        .background(WindowScreenReader(screen: $currentScreen).allowsHitTesting(false))
        .overlay(alignment: .top) {
            if camera.captureActivity.isRecording {
                RecordingTimeView(time: camera.captureActivity.currentTime)
                    .offset(y: isRegularSize ? 40 : 20)
            }
        }
        .overlay {
            StatusOverlayView(status: camera.status)
        }
    }
    
    /// This view arranges UI elements vertically.
    @ViewBuilder
    var compactUI: some View {
        VStack(spacing: 0) {
            FeaturesToolbar(camera: camera)
            Spacer()
            MainToolbar(camera: camera)
                .padding(.bottom, bottomPadding)
        }
    }
    
    /// This view arranges UI elements in a layered stack.
    @ViewBuilder
    var regularUI: some View {
        VStack {
            FeaturesToolbar(camera: camera)
            Spacer()
            ZStack {
                MainToolbar(camera: camera)
            }
            .frame(width: 740)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(12)
            .padding(.bottom, 32)
        }
    }
       
    var bottomPadding: CGFloat {
        // Dynamically calculate the offset for the bottom toolbar in iOS.
        // Prefer a UIScreen from the current view context, fall back if unavailable.
        let screen = currentScreen
        let bounds: CGRect
        if let screen {
            bounds = screen.bounds
        } else {
            // Fallback for older platforms or early lifecycle before window is attached.
            bounds = UIScreen.main.bounds
        }
        let rect = AVMakeRect(aspectRatio: movieAspectRatio, insideRect: bounds)
        return (rect.minY.rounded() / 2)+12
    }
}

/// A helper view that exposes the UIScreen from the current window context.
private struct WindowScreenReader: UIViewRepresentable {
    @Binding var screen: UIScreen?
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.isUserInteractionEnabled = false
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        // Obtain the window’s screen when available.
        if let window = uiView.window, let s = window.windowScene?.screen {
            if screen !== s {
                screen = s
            }
        }
    }
}

#Preview {
    CameraUI(camera: PreviewCameraModel())
}
