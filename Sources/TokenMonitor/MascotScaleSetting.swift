import Foundation

enum MascotScaleSetting {
    static let minimum = 0.10
    static let maximum = 3.00
    static let defaultValue = 1.00
    static let step = 0.10

    static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return defaultValue }
        return min(max(value, minimum), maximum)
    }

    static func percentage(_ value: Double) -> Int {
        Int((clamped(value) * 100).rounded())
    }
}

enum DesktopWidgetLayout {
    static let basePanelSize = CGSize(width: 370, height: 455)
    static let mascotFrameSize = CGSize(width: 330, height: 270)

    static func panelSize(for scale: Double) -> CGSize {
        let clampedScale = CGFloat(MascotScaleSetting.clamped(scale))
        return CGSize(
            width: max(basePanelSize.width, mascotFrameSize.width * clampedScale),
            height: max(basePanelSize.height, mascotFrameSize.height * clampedScale)
        )
    }
}
