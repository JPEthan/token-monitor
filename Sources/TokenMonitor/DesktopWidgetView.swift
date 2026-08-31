import AppKit
import SwiftUI

struct DesktopWidgetView: View {
    @ObservedObject var model: MonitorViewModel
    @ObservedObject var presentation: DesktopWidgetPresentation
    let onRefresh: () -> Void
    let onClose: () -> Void
    let onScaleChange: (Double) -> Void

    @State private var mascotIsBouncing = false
    @State private var controlsVisible = false

    private let accent = Color(red: 0.39, green: 0.40, blue: 0.68)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())

            mascot
                .frame(
                    width: DesktopWidgetLayout.mascotFrameSize.width,
                    height: DesktopWidgetLayout.mascotFrameSize.height
                )
                .position(x: mascotX, y: mascotY)

            if model.widgetBubbleVisible {
                thoughtBubble
                    .position(x: bubbleX, y: 91 + compactBubbleYOffset)
                    .transition(.scale(scale: 0.78, anchor: bubbleAnchor).combined(with: .opacity))

                thoughtDot(size: 18)
                    .position(x: firstDotX, y: 163 + compactBubbleYOffset)
                    .transition(.scale.combined(with: .opacity))

                thoughtDot(size: 11)
                    .position(x: secondDotX, y: 184 + compactBubbleYOffset)
                    .transition(.scale.combined(with: .opacity))
            }

            controls
                .position(x: controlsX, y: 38)
                .opacity(controlsVisible ? 1 : 0.3)
        }
        .frame(width: widgetSize.width, height: widgetSize.height)
        .onHover { controlsVisible = $0 }
        .onChange(of: model.mascotScale) { newScale in
            onScaleChange(newScale)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: model.widgetBubbleVisible)
        .animation(.easeInOut(duration: 0.18), value: presentation.isMirrored)
    }

    private var mascot: some View {
        Group {
            if let image = MascotAsset.image {
                ZStack {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .blur(radius: 0.72)
                        .opacity(0.72)
                        .accessibilityHidden(true)

                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                }
                .compositingGroup()
                .drawingGroup(opaque: false, colorMode: .linear)
            } else {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.purple.opacity(0.7))
                    .padding(70)
            }
        }
        .scaleEffect(
            x: presentation.isMirrored ? -mascotScale : mascotScale,
            y: mascotScale * (mascotIsBouncing ? 0.88 : 1),
            anchor: .bottom
        )
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            bounceAndRefresh()
        }
        .help(model.text(.mascotHelp))
        .accessibilityLabel(model.text(.mascotAccessibility))
    }

    private var thoughtBubble: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color.white.opacity(0.98))
                .overlay {
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(accent, lineWidth: 4)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 3)

            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Text(model.text(.appTitle))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    if model.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .foregroundStyle(accent)

                Text(primaryValue)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.31, green: 0.34, blue: 0.62))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(secondaryValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(model.statusIsError ? .red : Color.gray)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .padding(.horizontal, 14)
        }
        .frame(width: 244, height: 126)
        .onTapGesture {
            model.hideWidgetBubble()
        }
        .help(model.text(.hideBubble))
    }

    private func thoughtDot(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.98))
            .overlay {
                Circle()
                    .stroke(accent, lineWidth: 4)
            }
            .shadow(color: Color.black.opacity(0.16), radius: 3, x: 0, y: 2)
            .frame(width: size, height: size)
    }

    private var controls: some View {
        VStack(spacing: 7) {
            Button(action: bounceAndRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .help(model.text(.refreshHelp))
            .accessibilityLabel(model.text(.refresh))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .help(model.text(.close))
            .accessibilityLabel(model.text(.close))
        }
        .foregroundStyle(Color(red: 0.30, green: 0.34, blue: 0.58))
    }

    private func bounceAndRefresh() {
        model.playDuckSound()
        withAnimation(.easeOut(duration: 0.08)) {
            mascotIsBouncing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.48)) {
                mascotIsBouncing = false
            }
        }
        onRefresh()
    }

    private var primaryValue: String {
        guard model.hasSavedAPIKey else { return model.text(.notConfigured) }
        switch model.widgetBubbleContent {
        case .tokenUsage:
            return "\(model.text(.remainingShort)) \(TokenFormat.compact(model.remainingTokens))"
        case .estimatedCost:
            return "≈ \(model.estimatedCostText)"
        }
    }

    private var secondaryValue: String {
        guard model.hasSavedAPIKey else {
            return model.text(.enterAdminKey)
        }
        if model.statusIsError {
            return model.text(.syncFailed)
        }
        switch model.widgetBubbleContent {
        case .tokenUsage:
            return "\(model.text(.used)) \(TokenFormat.compact(model.usedTokens)) / \(TokenFormat.compact(model.monthlyTokenLimit))"
        case .estimatedCost:
            return "\(model.pricingModel.displayName) · \(model.text(.estimatedShort))"
        }
    }

    private var mascotScale: CGFloat { CGFloat(model.mascotScale) }
    private var widgetSize: CGSize { DesktopWidgetLayout.panelSize(for: model.mascotScale) }
    private var mascotX: CGFloat {
        let scaledWidth = DesktopWidgetLayout.mascotFrameSize.width * mascotScale
        return presentation.isMirrored ? scaledWidth / 2 : widgetSize.width - scaledWidth / 2
    }
    private var mascotY: CGFloat {
        widgetSize.height - DesktopWidgetLayout.mascotFrameSize.height / 2
    }
    private var bubbleDirection: CGFloat { presentation.isMirrored ? 1 : -1 }
    private var bubbleX: CGFloat {
        min(max(mascotX + bubbleDirection * 73, 122), widgetSize.width - 122)
    }
    private var firstDotX: CGFloat {
        min(max(mascotX + bubbleDirection * 81, 9), widgetSize.width - 9)
    }
    private var secondDotX: CGFloat {
        min(max(mascotX + bubbleDirection * 55, 5.5), widgetSize.width - 5.5)
    }
    private var compactBubbleYOffset: CGFloat {
        let scaledMascotTop = widgetSize.height
            - DesktopWidgetLayout.mascotFrameSize.height * mascotScale
        return max(scaledMascotTop - 185, 0)
    }
    private var controlsX: CGFloat { presentation.isMirrored ? 26 : widgetSize.width - 26 }
    private var bubbleAnchor: UnitPoint { presentation.isMirrored ? .bottomLeading : .bottomTrailing }
}

private enum MascotAsset {
    @MainActor
    static let image: NSImage? = {
        if let bundled = Bundle.main.url(
            forResource: "dragon-chibi-neutral-v4",
            withExtension: "png",
            subdirectory: "Mascot"
        ) {
            return NSImage(contentsOf: bundled)
        }

        let developmentURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/Mascot/dragon-chibi-neutral-v4.png")
        return NSImage(contentsOf: developmentURL)
    }()
}
