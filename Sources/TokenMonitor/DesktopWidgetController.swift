import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class DesktopWidgetPresentation: ObservableObject {
    @Published var isMirrored = false
}

@MainActor
final class DesktopWidgetController: NSObject, NSWindowDelegate {
    private enum PositionKeys {
        static let x = "desktopWidgetOriginX"
        static let y = "desktopWidgetOriginY"
        static let mirrored = "desktopWidgetMirrored"
    }

    private let presentation = DesktopWidgetPresentation()
    private var panel: DesktopMascotPanel?
    private var hasPositionedPanel = false
    private var snapTask: Task<Void, Never>?
    private var isSnapping = false

    func show(model: MonitorViewModel) {
        let panel = panel ?? makePanel(model: model)
        placeAtRememberedPositionIfNeeded(panel)
        panel.orderFrontRegardless()
        model.revealWidgetBubble()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel(model: MonitorViewModel) -> DesktopMascotPanel {
        let size = NSSize(width: 370, height: 455)
        let panel = DesktopMascotPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let rootView = DesktopWidgetView(
            model: model,
            presentation: presentation,
            onRefresh: {
                Task { await model.refresh(revealWidget: true) }
            },
            onClose: { [weak self] in
                self?.hide()
            }
        )
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        panel.delegate = self

        self.panel = panel
        return panel
    }

    private func placeAtRememberedPositionIfNeeded(_ panel: NSPanel) {
        guard !hasPositionedPanel else { return }

        let defaults = UserDefaults.standard
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        else { return }

        let visible = screen.visibleFrame
        let fallback = NSPoint(
            x: visible.maxX - panel.frame.width - 18,
            y: visible.minY + 14
        )

        var origin = fallback
        if defaults.object(forKey: PositionKeys.x) != nil,
           defaults.object(forKey: PositionKeys.y) != nil {
            origin = NSPoint(
                x: defaults.double(forKey: PositionKeys.x),
                y: defaults.double(forKey: PositionKeys.y)
            )
        }

        origin.x = min(max(origin.x, visible.minX + 10), visible.maxX - panel.frame.width - 10)
        origin.y = min(max(origin.y, visible.minY + 10), visible.maxY - panel.frame.height - 10)
        panel.setFrameOrigin(origin)

        presentation.isMirrored = defaults.object(forKey: PositionKeys.mirrored) == nil
            ? false
            : defaults.bool(forKey: PositionKeys.mirrored)
        hasPositionedPanel = true
    }

    func windowDidMove(_ notification: Notification) {
        guard
            !isSnapping,
            let movedPanel = notification.object as? NSPanel,
            movedPanel === panel
        else { return }

        snapTask?.cancel()
        snapTask = Task { [weak self, weak movedPanel] in
            do {
                repeat {
                    try await Task.sleep(for: .milliseconds(90))
                } while NSEvent.pressedMouseButtons != 0
            } catch {
                return
            }
            guard let self, let movedPanel else { return }
            self.snapToNearestEdge(movedPanel)
        }
    }

    private func snapToNearestEdge(_ panel: NSPanel) {
        guard !isSnapping else { return }
        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        else { return }

        let visible = screen.visibleFrame
        let padding: CGFloat = 10
        let shouldMirror = panel.frame.midX < visible.midX
        var destination = panel.frame.origin
        destination.x = shouldMirror
            ? visible.minX + padding
            : visible.maxX - panel.frame.width - padding

        destination.y = min(
            max(destination.y, visible.minY + padding),
            visible.maxY - panel.frame.height - padding
        )

        let verticalSnapDistance: CGFloat = 72
        if abs(panel.frame.minY - visible.minY) < verticalSnapDistance {
            destination.y = visible.minY + padding
        } else if abs(panel.frame.maxY - visible.maxY) < verticalSnapDistance {
            destination.y = visible.maxY - panel.frame.height - padding
        }

        let savedDestination = destination
        isSnapping = true
        presentation.isMirrored = shouldMirror
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(savedDestination)
        } completionHandler: { [weak self] in
            UserDefaults.standard.set(savedDestination.x, forKey: PositionKeys.x)
            UserDefaults.standard.set(savedDestination.y, forKey: PositionKeys.y)
            UserDefaults.standard.set(shouldMirror, forKey: PositionKeys.mirrored)
            Task { @MainActor in
                self?.isSnapping = false
            }
        }
    }
}

private final class DesktopMascotPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
