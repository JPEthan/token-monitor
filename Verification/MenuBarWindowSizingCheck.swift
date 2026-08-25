import AppKit

@main
@MainActor
enum MenuBarWindowSizingCheck {
    static func main() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 390, height: 520),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        let anchoredTop = window.frame.maxY

        for _ in 0..<20 {
            MenuBarWindowSizing.apply(
                contentSize: NSSize(width: 390, height: 690),
                to: window
            )
            precondition(abs((window.contentView?.bounds.height ?? 0) - 690) < 0.5)
            precondition(abs(window.frame.maxY - anchoredTop) < 0.5)

            MenuBarWindowSizing.apply(
                contentSize: NSSize(width: 390, height: 520),
                to: window
            )
            precondition(abs((window.contentView?.bounds.height ?? 0) - 520) < 0.5)
            precondition(abs(window.frame.maxY - anchoredTop) < 0.5)
        }

        print("✓ 設定面板連續 20 次由 690 縮回 520，視窗頂部位置保持不變")
    }
}
