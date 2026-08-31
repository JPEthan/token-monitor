import Foundation

@main
enum MascotScaleCheck {
    static func main() {
        precondition(MascotScaleSetting.clamped(0.01) == 0.10)
        precondition(MascotScaleSetting.clamped(0.85) == 0.85)
        precondition(MascotScaleSetting.clamped(4.00) == 3.00)
        precondition(MascotScaleSetting.clamped(.nan) == 1.00)
        precondition(MascotScaleSetting.percentage(0.10) == 10)
        precondition(MascotScaleSetting.percentage(3.00) == 300)

        let smallPanel = DesktopWidgetLayout.panelSize(for: 0.10)
        precondition(smallPanel.width == 370)
        precondition(smallPanel.height == 455)

        let normalPanel = DesktopWidgetLayout.panelSize(for: 1.00)
        precondition(normalPanel.width == 370)
        precondition(normalPanel.height == 455)

        let largestPanel = DesktopWidgetLayout.panelSize(for: 3.00)
        precondition(largestPanel.width == 990)
        precondition(largestPanel.height == 810)

        print("✓ 龍娘大小限制為 10%～300%，動態桌寵視窗尺寸與百分比換算正確")
    }
}
