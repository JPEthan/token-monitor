import SwiftUI

@MainActor
private final class TokenMonitorAppDelegate: NSObject, NSApplicationDelegate {
    static var model: MonitorViewModel?
    static var desktopWidgetController: DesktopWidgetController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if
            let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
            let iconImage = NSImage(contentsOf: iconURL)
        {
            NSApplication.shared.applicationIconImage = iconImage
        }

        guard
            let model = Self.model,
            let controller = Self.desktopWidgetController
        else { return }

        Task { @MainActor in
            await model.startIfNeeded()
            controller.show(model: model)
        }
    }
}

@main
@MainActor
struct TokenMonitorApp: App {
    @NSApplicationDelegateAdaptor(TokenMonitorAppDelegate.self)
    private var appDelegate

    @StateObject private var model: MonitorViewModel
    private let desktopWidgetController: DesktopWidgetController

    init() {
        let model = MonitorViewModel()
        let controller = DesktopWidgetController()
        _model = StateObject(wrappedValue: model)
        desktopWidgetController = controller
        TokenMonitorAppDelegate.model = model
        TokenMonitorAppDelegate.desktopWidgetController = controller
    }

    var body: some Scene {
        MenuBarExtra {
            MonitorView(
                model: model,
                onShowDesktopWidget: {
                    desktopWidgetController.show(model: model)
                }
            )
                .task {
                    await model.startIfNeeded()
                }
        } label: {
            Label(model.menuBarText, systemImage: model.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
