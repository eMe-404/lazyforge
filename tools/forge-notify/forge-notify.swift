// forge-notify — Dynamic Island-style notification pill for Claude Code
//
// Reads a Claude Code Notification hook JSON payload from stdin.
// Allow (click only) → activates the exact Ghostty window that was
//   frontmost before the pill appeared, sends y↵.
// Allow (Return / Cmd+Enter) → sends y↵ silently, stays in current app.
// Deny (click or Escape) → sends n↵ silently, stays in current app.
//
// Requires Accessibility permission (System Settings → Privacy → Accessibility).
//
// Compile:  see install.sh (requires embedding Info.plist)
// Install:  ./install.sh

import Cocoa
import SwiftUI
import ApplicationServices

// MARK: - Input model

struct NotificationPayload: Decodable {
    let message: String?
    let title:   String?
}

// MARK: - Accessibility + AppleScript helpers

// Send y↵ to Ghostty and raise the exact tab that had focus before the pill appeared.
// Uses the AX element captured at launch (tab-level, not just window-level).
func allowInGhostty(axWindow: AXUIElement?, then done: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        // Raise the specific tab via Accessibility API.
        if let win = axWindow {
            AXUIElementPerformAction(win, kAXRaiseAction as CFString)
        }
        // Activate the Ghostty process so the raised tab comes to the foreground.
        NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.mitchellh.ghostty")
            .first?.activate(options: .activateIgnoringOtherApps)
        Thread.sleep(forTimeInterval: 0.15)
        let keystroke = """
        tell application "System Events"
            tell application process "Ghostty"
                keystroke "y"
                key code 36
            end tell
        end tell
        """
        if let s = NSAppleScript(source: keystroke) { var e: NSDictionary?; s.executeAndReturnError(&e) }
        DispatchQueue.main.async { done() }
    }
}

// Send y↵ to Ghostty in the background — user stays in current app.
// Used for keyboard shortcut (Return / Cmd+Enter).
func allowSilently(then done: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        let script = """
        tell application "System Events"
            tell application process "Ghostty"
                keystroke "y"
                key code 36
            end tell
        end tell
        """
        if let s = NSAppleScript(source: script) { var e: NSDictionary?; s.executeAndReturnError(&e) }
        DispatchQueue.main.async { done() }
    }
}

// Send n↵ to Ghostty in the background — user stays in current app.
func denyInGhostty(then done: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        let script = """
        tell application "System Events"
            tell application process "Ghostty"
                keystroke "n"
                key code 36
            end tell
        end tell
        """
        if let s = NSAppleScript(source: script) { var e: NSDictionary?; s.executeAndReturnError(&e) }
        DispatchQueue.main.async { done() }
    }
}

// Capture the AX element for Ghostty's focused tab *before* forge-notify changes focus.
// kAXFocusedWindowAttribute gives the specific tab element — not just the window container —
// so kAXRaiseAction later lands on the exact tab Claude was running in.
func ghosttyFocusedAXWindow() -> AXUIElement? {
    let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.mitchellh.ghostty")
    guard let app = apps.first else { return nil }
    let axApp = AXUIElementCreateApplication(app.processIdentifier)
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success,
          let v = value else { return nil }
    // swiftlint:disable:next force_cast
    return (v as! AXUIElement)
}

// MARK: - Catppuccin Mocha palette

extension Color {
    static let moBase    = Color(red: 0.118, green: 0.118, blue: 0.180)
    static let moSurface = Color(red: 0.192, green: 0.196, blue: 0.267)
    static let moText    = Color(red: 0.804, green: 0.839, blue: 0.957)
    static let moMauve   = Color(red: 0.796, green: 0.651, blue: 0.969)
    static let moGreen   = Color(red: 0.651, green: 0.890, blue: 0.631)
    static let moRed     = Color(red: 0.953, green: 0.545, blue: 0.659)
}

// MARK: - Pill view

struct PillView: View {
    let message:        String
    let onAllowClick:   () -> Void   // click: redirect to Ghostty
    let onAllowSilent:  () -> Void   // keyboard: stay in current app
    let onDeny:         () -> Void   // click or Escape: stay in current app

    @State private var visible  = false
    @State private var timeLeft = 30

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.moBase)
                .overlay(Capsule().strokeBorder(Color.moSurface, lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 6)

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Text("✦").font(.system(size: 13)).foregroundColor(.moMauve)
                    Text("CLAUDE")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.moMauve)
                        .tracking(1.2)
                }
                .frame(width: 76, alignment: .leading)

                Rectangle().fill(Color.moSurface).frame(width: 1, height: 26)

                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.moText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Deny — click or Escape, stays in current app
                Button(action: onDeny) {
                    Text("Deny")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.moRed)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.moRed.opacity(0.13))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

                // Allow — click only (redirects to Ghostty)
                Button(action: onAllowClick) {
                    Text("Allow  \(timeLeft)s")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.moGreen)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.moGreen.opacity(0.13))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                // No .keyboardShortcut here — keyboard handled by hidden button below
            }
            .padding(.horizontal, 18)

            // Hidden button: Return / Cmd+Enter → allow silently (no redirect)
            Button(action: onAllowSilent) { EmptyView() }
                .frame(width: 0, height: 0)
                .opacity(0)
                .keyboardShortcut(.return, modifiers: [])
                .keyboardShortcut(.return, modifiers: [.command])
        }
        .frame(height: 60)
        .scaleEffect(visible ? 1.0 : 0.82)
        .opacity(visible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) { visible = true }
            NSSound(named: .init("Glass"))?.play()
            startTimer()
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timeLeft > 1 { timeLeft -= 1 }
            else { t.invalidate(); onDeny() }
        }
    }
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let message: String
    let ghosttyAXWindow: AXUIElement?   // captured before we steal focus
    var keyMonitor: Any?                // global keyboard monitor (no app activation needed)

    init(message: String, ghosttyAXWindow: AXUIElement?) {
        self.message        = message
        self.ghosttyAXWindow = ghosttyAXWindow
    }

    func applicationDidFinishLaunching(_: Notification) {
        let screen = NSScreen.screens.first(where: {
            NSMouseInRect(NSEvent.mouseLocation, $0.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.visibleFrame

        let w: CGFloat = 520
        let h: CGFloat = 60
        let x = frame.minX + (frame.width - w) / 2
        let y = frame.maxY - h - 8

        // .nonactivatingPanel: clicks don't steal focus; first click hits the button directly.
        // This is how macOS system HUDs (volume, brightness) work.
        window = NSPanel(
            contentRect: .init(x: x, y: y, width: w, height: h),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        window.level              = .screenSaver
        window.backgroundColor    = .clear
        window.isOpaque           = false
        window.hasShadow          = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true

        let axWin = ghosttyAXWindow
        window.contentView = NSHostingView(rootView: PillView(
            message:       message,
            onAllowClick:  { allowInGhostty(axWindow: axWin) { exit(0) } },
            onAllowSilent: { allowSilently { exit(0) } },
            onDeny:        { denyInGhostty  { exit(0) } }
        ))

        // Show above everything without activating the app or switching Spaces.
        window.orderFrontRegardless()

        // Global keyboard monitor — works even when the browser (or any other app) has focus.
        // Return / Cmd+Return → allow silently; Escape → deny.
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            switch event.keyCode {
            case 36: // Return / Cmd+Return
                if let m = self.keyMonitor { NSEvent.removeMonitor(m); self.keyMonitor = nil }
                allowSilently { exit(0) }
            case 53: // Escape
                if let m = self.keyMonitor { NSEvent.removeMonitor(m); self.keyMonitor = nil }
                denyInGhostty { exit(0) }
            default: break
            }
        }
    }
}

// MARK: - Entry point

// Read stdin before app.run() — never blocks the main run loop.
let inputData = FileHandle.standardInput.readDataToEndOfFile()

var message = "Claude is waiting for your input"
if let p = try? JSONDecoder().decode(NotificationPayload.self, from: inputData) {
    message = p.message ?? p.title ?? message
}

// Capture the AX element for Ghostty's focused tab *before* forge-notify changes anything.
// kAXFocusedWindowAttribute is tab-level: it identifies the exact tab Claude is running in,
// not just the container window (which all tabs share).
let savedAXWindow = ghosttyFocusedAXWindow()

let app      = NSApplication.shared
let delegate = AppDelegate(message: message, ghosttyAXWindow: savedAXWindow)
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
