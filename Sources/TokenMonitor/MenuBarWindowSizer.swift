import AppKit
import SwiftUI

struct MenuBarWindowSizer: NSViewRepresentable {
    let contentSize: NSSize

    func makeNSView(context: Context) -> WindowAttachmentView {
        let view = WindowAttachmentView()
        view.contentSize = contentSize
        return view
    }

    func updateNSView(_ nsView: WindowAttachmentView, context: Context) {
        nsView.contentSize = contentSize
    }
}

final class WindowAttachmentView: NSView {
    var contentSize = NSSize(width: 390, height: 520) {
        didSet {
            guard oldValue != contentSize else { return }
            scheduleResize()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleResize()
    }

    private func scheduleResize() {
        let requestedSize = contentSize
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            MenuBarWindowSizing.apply(contentSize: requestedSize, to: window)

            // SwiftUI may finish a MenuBarExtra layout pass after updateNSView.
            // Reapply on the following run-loop turn so its cached larger fitting
            // size cannot win the race and recreate the transparent padding.
            DispatchQueue.main.async { [weak self, weak window] in
                guard
                    let self,
                    let window,
                    self.window === window,
                    self.contentSize == requestedSize
                else { return }
                MenuBarWindowSizing.apply(contentSize: requestedSize, to: window)
            }
        }
    }
}

@MainActor
enum MenuBarWindowSizing {
    static func apply(contentSize: NSSize, to window: NSWindow) {
        let anchoredTop = window.frame.maxY

        // MenuBarExtra may retain the largest intrinsic content size it has seen.
        // Reset both constraints before resizing so closing Settings can shrink
        // the actual AppKit window instead of leaving transparent top/bottom space.
        window.contentMinSize = contentSize
        window.contentMaxSize = contentSize
        window.setContentSize(contentSize)

        var correctedFrame = window.frame
        correctedFrame.origin.y = anchoredTop - correctedFrame.height
        window.setFrame(correctedFrame, display: true, animate: false)
        window.contentView?.layoutSubtreeIfNeeded()
        window.invalidateShadow()
    }
}
