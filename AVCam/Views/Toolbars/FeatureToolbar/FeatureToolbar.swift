/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents controls to enable capture features.
struct FeaturesToolbar<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    // Visual-only state for resolution / frame rate selector
    @State private var isShowingVideoOptions: Bool = false
    @State private var selectedResolution: ResolutionOption = .p1080
    @State private var selectedFrameRate: FrameRateOption = .fps240
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Resolution / FPS display button on the leading side
                resolutionFPSButton
                Spacer()
            }
            .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
            .padding([.leading, .trailing])
            // Hide the toolbar items when a person interacts with capture controls.
            .opacity(camera.prefersMinimizedUI ? 0 : 1)
            
            if isShowingVideoOptions {
                optionsPanel
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: isShowingVideoOptions)
    }
       
    @ViewBuilder
    var hdrButton: some View {
        if isCompactSize {
            hdrToggleButton
        } else {
            hdrToggleButton
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
    
    var hdrToggleButton: some View {
        Button {
            camera.isHDRVideoEnabled.toggle()
        } label: {
            Text("HDR \(camera.isHDRVideoEnabled ? "On" : "Off")")
                .font(.body.weight(.semibold))
        }
        .disabled(camera.captureActivity.isRecording)
    }
    
    @ViewBuilder
    var compactSpacer: some View {
        if !isRegularSize {
            Spacer()
        }
    }
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

extension FeaturesToolbar {
    
    private var resolutionFPSButton: some View {
        Button {
            isShowingVideoOptions.toggle()
        } label: {
            superscriptLabel(resolution: selectedResolution, fps: selectedFrameRate)
                // Thinner font than semibold; use regular by default
                .font(isRegularSize ? .body : .callout)
                .foregroundStyle(.primary)
                .padding(.horizontal, isRegularSize ? 12 : 10)
                .padding(.vertical, isRegularSize ? 8 : 6)
                .background(.regularMaterial.opacity(0.6))
                .background(Color.gray.opacity(0.25)) // subtle gray base
                .clipShape(Capsule())
        }
        .disabled(camera.captureActivity.isRecording)
    }
    
    // Create a label like "1080p 240FPS" with superscript "p" and "FPS".
    private func superscriptLabel(resolution: ResolutionOption, fps: FrameRateOption) -> some View {
        HStack(spacing: 6) {
            // Resolution "1080p" or "4K"/"720p"
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
            // FPS "240FPS" with superscript "FPS"
            HStack(spacing: 2) {
                Text("\(fps.rawValue)")
                Text("FPS").baselineOffset(6).font(.caption2.weight(.bold))
            }
        }
        .foregroundStyle(.primary)
    }
    
    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // RESOLUTION row (label and options on the same line, minimal spacing, top aligned)
            HStack(alignment: .top, spacing: 0) {
                rowLabel("RESOLUTION")
                HorizontalChips(spacing: 0) {
                    ForEach(ResolutionOption.allCases) { item in
                        chip(
                            isSelected: item == selectedResolution,
                            content: {
                                switch item {
                                case .k4: Text("4K")
                                        .font(.default.weight(.regular))
                                case .p1080:
                                    HStack(spacing: 0) {
                                        Text("1080")                                                                                .font(.default.weight(.regular))

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
            }
            
            // FRAME RATE row (label and options on the same line, minimal spacing, top aligned)
            HStack(alignment: .top, spacing: 0) {
                rowLabel("FRAME RATE")
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
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        // No background per request
    }
    
    private func rowLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(alignment: .topLeading) // align label to the top
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
