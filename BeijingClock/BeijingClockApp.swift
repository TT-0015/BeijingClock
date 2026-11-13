import SwiftUI
import AppKit

@main
struct BeijingClockApp: App {
    @NSApplicationDelegateAdaptor(ClockAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {}
            CommandGroup(after: .toolbar) {
                Button("Toggle Full Screen") {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
            }
        }
    }
}

private final class ClockAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private let activity = ClockActivity()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = ClockWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 110),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.title = "BeijingClock"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isOpaque = true
        window.backgroundColor = .black
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenPrimary]
        window.contentMinSize = NSSize(width: 300, height: 110)
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        let content = NSHostingView(rootView: ClockView(activity: activity))
        content.sizingOptions = []
        window.contentView = content
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            window.toggleFullScreen(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        return true
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        activity.isVisible = window?.occlusionState.contains(.visible) ?? false
        if !activity.isVisible {
            (window as? ClockWindow)?.restoreCursor()
        }
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        (window as? ClockWindow)?.hideCursorIfAppropriate()
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        (window as? ClockWindow)?.restoreCursor()
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        (window as? ClockWindow)?.restoreCursor()
    }

    func windowDidResignKey(_ notification: Notification) {
        (window as? ClockWindow)?.restoreCursor()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        (window as? ClockWindow)?.scheduleCursorHide()
    }
}

private final class ClockWindow: NSWindow {
    private var cursorIdleTimer: Timer?
    private var hidesCursor = false

    override func sendEvent(_ event: NSEvent) {
        super.sendEvent(event)
        switch event.type {
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
             .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel:
            scheduleCursorHide()
        default:
            break
        }
    }

    func scheduleCursorHide() {
        if hidesCursor {
            NSCursor.setHiddenUntilMouseMoves(false)
            hidesCursor = false
        }
        guard styleMask.contains(.fullScreen), isKeyWindow, NSApp.isActive else { return }
        if let cursorIdleTimer {
            cursorIdleTimer.fireDate = Date(timeIntervalSinceNow: 2)
        } else {
            let timer = Timer(timeInterval: 2, repeats: false) { [weak self] _ in
                self?.cursorIdleTimer = nil
                self?.hideCursorIfAppropriate()
            }
            timer.tolerance = 0.3
            cursorIdleTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func hideCursorIfAppropriate() {
        guard styleMask.contains(.fullScreen), isKeyWindow, NSApp.isActive,
              frame.contains(NSEvent.mouseLocation) else { return }
        NSCursor.setHiddenUntilMouseMoves(true)
        hidesCursor = true
    }

    func restoreCursor() {
        cursorIdleTimer?.invalidate()
        cursorIdleTimer = nil
        if hidesCursor {
            NSCursor.setHiddenUntilMouseMoves(false)
            hidesCursor = false
        }
    }

    override func cancelOperation(_ sender: Any?) {
        if styleMask.contains(.fullScreen) {
            toggleFullScreen(sender)
        }
    }
}

private final class ClockActivity: ObservableObject {
    @Published var isVisible = true
}

private struct ClockView: View {
    @ObservedObject var activity: ClockActivity
    private static let start = Date(timeIntervalSince1970: floor(Date.now.timeIntervalSince1970))
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        GeometryReader { geometry in
            Group {
                if activity.isVisible {
                    TimelineView(.periodic(from: Self.start, by: 1)) { _ in
                        Text(Self.formatter.string(from: .now))
                    }
                } else {
                    Text(Self.formatter.string(from: .now))
                }
            }
            .font(.system(size: min(200, min(geometry.size.width * 0.16, geometry.size.height * 0.44)), weight: .light))
            .monospacedDigit()
            .foregroundStyle(.white)
            .accessibilityIdentifier("beijing-time")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transaction { $0.animation = nil }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
