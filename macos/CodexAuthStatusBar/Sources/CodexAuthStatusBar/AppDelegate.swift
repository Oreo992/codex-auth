import AppKit
import CodexAuthStatusBarCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = StatusBarController()
    }
}

@main
struct CodexAuthStatusBarApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class StatusBarController {
    private let panelWidth: CGFloat = 302
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let store: AccountStore

    init() {
        store = AccountStore()
        configureStatusItem()
        configurePopover()
        store.onActiveSummaryChange = { [weak self] summary in
            self?.statusItem.button?.toolTip = summary
        }
        store.onPanelHeightChange = { [weak self] height in
            self?.popover.contentSize = NSSize(width: self?.panelWidth ?? 302, height: height)
        }
        Task { await store.refresh(refreshFromAPI: false) }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: "Codex Auth")
        image?.size = NSSize(width: 13, height: 13)
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = "Codex Auth"
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: panelWidth, height: store.panelHeight)
        popover.contentViewController = NSHostingController(rootView: AccountPanelView(store: store))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
