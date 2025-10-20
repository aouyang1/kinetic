/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents only the resolution / frame rate selector button and its options.
struct FeaturesToolbar<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    // Visual-only state for resolution / frame rate selector
    @State private var isShowingVideoOptions: Bool = false
    @State private var selectedResolution: ResolutionOption = .p1080
    @State private var selectedFrameRate: FrameRateOption = .fps240
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background dimmer behind the anchored modal; tap outside to dismiss
            if isShowingVideoOptions {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isShowingVideoOptions = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            // Base toolbar content
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    // Capsule-styled pill button
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) {
                            isShowingVideoOptions.toggle()
                        }
                    } label: {
                        superscriptLabel(resolution: selectedResolution, fps: selectedFrameRate)
                            .font(isRegularSize ? .body : .callout)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .disabled(camera.captureActivity.isRecording)
                    .buttonStyle(.plain)
                }
                .padding([.leading, .trailing])
                .padding(.top, 20) // lower the button by 20
                // Hide when capture controls are fullscreen.
                .opacity(camera.prefersMinimizedUI ? 0 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .zIndex(2)
            // Overlay the full-width modal just below the button row
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    // Spacer equal to the vertical space occupied by the button row
                    // so the modal appears just below the button
                    Color.clear
                        .frame(height: 20 + (isRegularSize ? 44 : 36)) // approximate button row height + the 20 offset
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isShowingVideoOptions {
                        modalCard
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(3)
                    }
                }
            }
        }
        .animation(.easeInOut, value: isShowingVideoOptions)
    }
    
    // MARK: - Visual-only Resolution / FPS
    
    private enum ResolutionOption: String, CaseIterable, Identifiable {
        case k4 = "4K"
        case p1080 = "1080p"
        case p720 = "720p"
        var id: String { rawValue }
    }
    
    private enum FrameRateOption: Int, CaseIterable, Identifiable {
        case fps30 = 30
        case fps60 = 60
        case fps120 = 120
        case fps240 = 240
        var id: Int { rawValue }
    }
    
    // Create a label like "1080p 240FPS" with superscript "P" and "FPS".
    private func superscriptLabel(resolution: ResolutionOption, fps: FrameRateOption) -> some View {
        HStack(spacing: 6) {
            Group {
                switch resolution {
                case .k4:
                    Text("4K")
                case .p1080:
                    HStack(spacing: 0) {
                        Text("1080")
                        Text("P").baselineOffset(6).font(.caption2.weight(.bold))
                    }
                case .p720:
                    HStack(spacing: 0) {
                        Text("720")
                        Text("P").baselineOffset(6).font(.caption2.weight(.bold))
                    }
                }
            }
            HStack(spacing: 2) {
                Text("\(fps.rawValue)")
                Text("FPS").baselineOffset(6).font(.caption2.weight(.bold))
            }
        }
        .foregroundStyle(.primary)
    }
    
    // Modal card anchored below the button and spanning the full screen width
    private var modalCard: some View {
        VStack(spacing: 0) {
            // Drag handle or title row (optional)
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 8)
            
            // The options content
            modalOptionsContent
                .padding(.horizontal)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity) // full screen width within overlay
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 10)
        .padding(.horizontal, 12)
        // Swallow taps so inside taps don’t dismiss
        .onTapGesture { /* swallow taps inside modal */ }
    }
    
    // The content shown inside the modal
    private var modalOptionsContent: some View {
        // Two-column grid: left = label, right = chips (trailing aligned)
        Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                rowLabel("RESOLUTION")
                    .gridColumnAlignment(.leading)
                HorizontalChips(spacing: 0) {
                    ForEach(ResolutionOption.allCases) { item in
                        chip(
                            isSelected: item == selectedResolution,
                            content: {
                                switch item {
                                case .k4:
                                    Text("4K")
                                        .font(.default.weight(.regular))
                                case .p1080:
                                    HStack(spacing: 0) {
                                        Text("1080")
                                            .font(.default.weight(.regular))
                                    }
                                case .p720:
                                    HStack(spacing: 0) {
                                        Text("720")
                                            .font(.default.weight(.regular))
                                    }
                                }
                            },
                            action: {
                                withAnimation(.easeInOut) { selectedResolution = item }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            GridRow {
                rowLabel("FRAME RATE")
                    .gridColumnAlignment(.leading)
                HorizontalChips(spacing: 0) {
                    ForEach(FrameRateOption.allCases) { item in
                        chip(
                            isSelected: item == selectedFrameRate,
                            content: {
                                HStack(spacing: 0) {
                                    Text("\(item.rawValue)")
                                        .font(.default.weight(.regular))
                                }
                            },
                            action: {
                                withAnimation(.easeInOut) { selectedFrameRate = item }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    private func rowLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(alignment: .topLeading)
    }
    
    // A single chip button with text-only styling (no background or stroke).
    @ViewBuilder
    private func chip<Label: View>(isSelected: Bool, @ViewBuilder content: () -> Label, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            content()
                .padding(.horizontal, 6) // light padding to increase hit target
                .padding(.vertical, 0)
                .foregroundStyle(isSelected ? Color.yellow : Color.primary)
                .font(.callout.weight(.semibold))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizontal chips scroller

/// A horizontally scrolling container for chip-like content.
private struct HorizontalChips<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content
    
    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content
            }
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Preview

#Preview("FeaturesToolbar") {
    // Use the preview camera model provided by the project.
    FeaturesToolbar(camera: PreviewCameraModel())
        .padding()
        .background(Color.black.opacity(0.6))
        .previewLayout(.sizeThatFits)
}
