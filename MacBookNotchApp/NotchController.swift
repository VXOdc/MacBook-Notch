import AppKit
import SwiftUI

/// Owns the borderless notch overlay window and the menu bar item.
final class NotchController {
    private let panel: NSPanel
    private let nowPlaying = NowPlaying()
    private var statusItem: NSStatusItem?
    private var observer: NSObjectProtocol?

    init() {
        let collapsed = collapsedSize

        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: collapsed),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.animationBehavior = .none

        let rootView = NotchView(
            nowPlaying: nowPlaying,
            collapsedWidth: collapsed.width,
            collapsedHeight: collapsed.height
        ) { [weak self] width, height in
            self?.setPanelSize(width: width, height: height)
        }
        panel.contentView = NSHostingView(rootView: rootView)
        positionPanel(collapsed)
        panel.orderFrontRegardless()

        // Re-position if displays change (plugged in a monitor, changed resolution, etc.)
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.positionPanel(self.collapsedSize)
        }

        makeStatusItem()
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Screen geometry

    /// Prefer the built-in notched display; fall back to the main screen.
    private var screen: NSScreen {
        if let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notched
        }
        // macOS always has at least one screen while an application is running.
        // Avoid constructing NSScreen directly: it has no public initializer.
        return NSScreen.main ?? NSScreen.screens.first!
    }

    private var hasNotch: Bool { screen.safeAreaInsets.top > 0 }

    /// The rectangle covered by the physical notch, or a small pill just
    /// below the menu bar on displays without a notch.
    private var notchRect: CGRect {
        let s = screen
        let f = s.frame
        if hasNotch {
            let left = s.auxiliaryTopLeftArea?.width ?? 0
            let right = s.auxiliaryTopRightArea?.width ?? 0
            let width = min(max(f.width - left - right, 120), 420)
            let height = s.safeAreaInsets.top
            return CGRect(x: f.midX - width / 2, y: f.maxY - height, width: width, height: height)
        } else {
            let width: CGFloat = 176
            let height: CGFloat = 32
            return CGRect(x: f.midX - width / 2, y: s.visibleFrame.maxY - height, width: width, height: height)
        }
    }

    private var collapsedSize: CGSize {
        let r = notchRect
        return CGSize(width: max(r.width, 140), height: max(r.height, 30))
    }

    // MARK: - Window placement

    /// Places the panel so its top edge sits flush with the top of the screen,
    /// centered horizontally. The window grows downward when expanded.
    private func positionPanel(_ size: CGSize) {
        let s = screen
        let f = s.frame
        var y = f.maxY - size.height
        if !hasNotch { y = s.visibleFrame.maxY - size.height }
        panel.setFrame(NSRect(x: f.midX - size.width / 2, y: y, width: size.width, height: size.height), display: true)
    }

    private func setPanelSize(width: CGFloat, height: CGFloat) {
        let s = screen
        let f = s.frame
        var y = f.maxY - height
        if !hasNotch { y = s.visibleFrame.maxY - height }
        panel.setFrame(NSRect(x: f.midX - width / 2, y: y, width: width, height: height), display: true, animate: true)
    }

    // MARK: - Menu bar item

    private func makeStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "MacBook Notch App")

        let menu = NSMenu()
        let about = NSMenuItem(title: "About MacBook Notch App", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MacBook Notch App", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(
            options: [
                .applicationName: "MacBook Notch App",
                .applicationVersion: "1.0",
            ]
        )
    }
}
