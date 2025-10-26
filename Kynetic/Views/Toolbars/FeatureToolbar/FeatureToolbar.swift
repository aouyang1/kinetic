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
    
    // Dynamic selections derived from camera.availableVideoFormats
    @State private var selectedFormatID: String? = nil
    @State private var selectedFPS: Int? = nil
    
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
                        superscriptLabel(
                            resolutionText: selectedResolutionLabel,
                            fpsText: selectedFPSText
                        )
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
        // Initialize selections when formats become available or change.
        .onChange(of: camera.availableVideoFormats, initial: true) { _, _ in
            initializeSelectionsIfNeeded()
        }
        // Keep FPS selection valid when resolution changes.
        .onChange(of: selectedFormatID) { _, _ in
            coerceSelectedFPSToValidOption()
        }
    }
    
    // MARK: - Derived data from available formats
    
    // Group formats by marketingName and choose the highest pixel count per group.
    private var groupedResolutionFormats: [(label: String, format: VideoFormatInfo)] {
        // Build groups by marketingName.
        var bestByName: [String: VideoFormatInfo] = [:]
        for format in camera.availableVideoFormats {
            let key = format.marketingName
            if let existing = bestByName[key] {
                // Keep the one with more pixels, break ties by max fps.
                let lhs = format.sortKey
                let rhs = existing.sortKey
                if lhs.pixels > rhs.pixels || (lhs.pixels == rhs.pixels && lhs.maxFps > rhs.maxFps) {
                    bestByName[key] = format
                }
            } else {
                bestByName[key] = format
            }
        }
        // Sort by pixel count ascending? Change to descending so highest appears first.
        let sorted = bestByName.values.sorted {
            let l = $0.sortKey
            let r = $1.sortKey
            if l.pixels != r.pixels { return l.pixels < r.pixels }
            return l.maxFps > r.maxFps
        }
        // Map to tuples for easier rendering.
        return sorted.map { (label: $0.marketingName, format: $0) }
    }
    
    private var selectedFormat: VideoFormatInfo? {
        guard let id = selectedFormatID else { return nil }
        return camera.availableVideoFormats.first(where: { $0.id == id })
    }
    
    private var fpsOptionsForSelected: [Int] {
        guard let fmt = selectedFormat else { return [] }
        // Present fps highest-first.
        return fmt.fpsOptions.sorted(by: <)
    }
    
    // MARK: - Selection initialization and coercion
    
    private func initializeSelectionsIfNeeded() {
        // If we already have a selected format that still exists, keep it.
        if let id = selectedFormatID,
           camera.availableVideoFormats.contains(where: { $0.id == id }) {
            coerceSelectedFPSToValidOption()
            return
        }
        // Otherwise, pick the first grouped resolution (highest quality by our sort).
        if let first = groupedResolutionFormats.first?.format {
            selectedFormatID = first.id
            // Prefer a common high fps if available; else highest available.
            if let preferred = ([240, 120, 60, 30].first { first.fpsOptions.contains($0) }) {
                selectedFPS = preferred
            } else {
                selectedFPS = first.fpsOptions.sorted(by: >).first
            }
        } else {
            // No formats available; clear selections.
            selectedFormatID = nil
            selectedFPS = nil
        }
    }
    
    private func coerceSelectedFPSToValidOption() {
        let options = fpsOptionsForSelected
        guard !options.isEmpty else {
            selectedFPS = nil
            return
        }
        if let fps = selectedFPS, options.contains(fps) {
            // Keep current selection.
            return
        }
        // Choose the highest available by default.
        selectedFPS = options.first
    }
    
    // MARK: - Label builders
    
    // Create a label like "1080p 240FPS" with superscript "P" and "FPS".
    private func superscriptLabel(resolutionText: String, fpsText: String) -> some View {
        HStack(spacing: 6) {
            resolutionSuperscript(resolutionText)
            fpsSuperscript(fpsText)
        }
        .foregroundStyle(.primary)
    }
    
    private func resolutionSuperscript(_ text: String) -> some View {
        // If it ends with "p" or "P", render the trailing P as superscript.
        if text.lowercased().hasSuffix("p"), let numberPart = text.split(separator: "p").first {
            return AnyView(
                HStack(spacing: 0) {
                    Text(String(numberPart))
                    Text("P").baselineOffset(6).font(.caption2.weight(.bold))
                }
            )
        } else {
            return AnyView(Text(text))
        }
    }
    
    private func fpsSuperscript(_ text: String) -> some View {
        HStack(spacing: 2) {
            // Expect "240FPS", "120FPS", etc. If not, just show as-is.
            if let number = Int(text.replacingOccurrences(of: "FPS", with: "")) {
                Text("\(number)")
                Text("FPS").baselineOffset(6).font(.caption2.weight(.bold))
            } else {
                Text(text)
            }
        }
    }
    
    private var selectedResolutionLabel: String {
        guard let fmt = selectedFormat else { return "—" }
        // Prefer marketingName if it’s a common one; otherwise WIDTHxHEIGHT.
        switch fmt.marketingName {
        case "4K", "1080p", "720p":
            return fmt.marketingName
        default:
            return "\(fmt.width)x\(fmt.height)"
        }
    }
    
    private var selectedFPSText: String {
        if let fps = selectedFPS {
            return "\(fps)FPS"
        }
        return "—"
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
        Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 16) {
            GridRow {
                rowLabel("RESOLUTION")
                    .gridColumnAlignment(.leading)
                HorizontalChips(spacing: 0) {
                    ForEach(groupedResolutionFormats, id: \.format.id) { entry in
                        chip(
                            isSelected: entry.format.id == selectedFormatID,
                            content: {
                                Text(entry.label)
                                    .font(.default.weight(.regular))
                            },
                            action: {
                                withAnimation(.easeInOut) {
                                    selectedFormatID = entry.format.id
                                }
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
                    ForEach(fpsOptionsForSelected, id: \.self) { fps in
                        chip(
                            isSelected: fps == selectedFPS,
                            content: {
                                Text("\(fps)")
                                    .font(.default.weight(.regular))
                            },
                            action: {
                                withAnimation(.easeInOut) {
                                    selectedFPS = fps
                                }
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
    
    // A single chip button with a larger tap target.
    @ViewBuilder
    private func chip<Label: View>(isSelected: Bool, @ViewBuilder content: () -> Label, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            content()
                // Visual padding for the label
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                // Enlarge the hit area without changing visuals much
                .contentShape(Rectangle())
                .padding(.horizontal, 8) // extra invisible hit padding
                .padding(.vertical, 6)   // extra invisible hit padding
                .background(Color.clear) // keep look unchanged
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
