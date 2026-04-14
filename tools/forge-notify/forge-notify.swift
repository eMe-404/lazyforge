// forge-notify — Dynamic Island-style notification pill for Claude Code
//
// Reads a Claude Code Notification hook JSON payload from stdin.
// Displays a floating pill with Allow / Deny buttons that send keystrokes
// to Ghostty so the user can answer Claude Code permission prompts without
// switching windows.
//
// Requires Accessibility permission (System Settings → Privacy → Accessibility).
//
// Compile:  see install.sh (requires embedding Info.plist)
// Install:  ./install.sh

import Cocoa
import SwiftUI

// MARK: - Input model

struct NotificationPayload: Decodable {
    let message: String?
    let title:   String?
}

// MARK: - Keystroke helper

func sendToGhostty(_ key: String, then completion: @escaping () -> Void) {
    // Activate Ghostty and send a keystroke + Return to answer the prompt.
    // Runs off the main thread so the pill animates out before the window switches.
    let script = """
    tell application "Ghostty" to activate
    delay 0.12
    tell application "System Events"
        keystroke "\(key)"
        key code 36
    end tell
    """
    DispatchQueue.global(qos: .userInitiated).async {
        if let s = NSAppleScript(source: script) {
            var err: NSDictionary?
            s.executeAndReturnError(&err)
        }
        DispatchQueue.main.async { completion() }
    }
}

// MARK: - Catppuccin Mocha palette

extension Color {
    static let moBase    = Color(red: 0.118, green: 0.118, blue: 0.180) // #1e1e2e
    static let moSurface = Color(red: 0.192, green: 0.196, blue: 0.267) // #313244
    static let moText    = Color(red: 0.804, green: 0.839, blue: 0.957) // #cdd6f4
    static let moMauve   = Color(red: 0.796, green: 0.651, blue: 0.969) // #cba6f7
    static let moGreen   = Color(red: 0.651, green: 0.890, blue: 0.631) // #a6e3a1
    static let moRed     = Color(red: 0.953, green: 0.545, blue: 0.659) // #f38ba8
}

// MARK: - Pill view

struct PillView: View {
    let message:  String
    let onAllow:  () -> Void
    let onDeny:   () -> Void

    @State private var visible  = false
    @State private var timeLeft = 30

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.moBase)
                .overlay(Capsule().strokeBorder(Color.moSurface, lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 6)

            HStack(spacing: 12) {
                // Claude badge
                HStack(spacing: 5) {
                    Text("✦")
                        .font(.system(size: 13))
                        .foregroundColor(.moMauve)
                    Text("CLAUDE")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.moMauve)
                        .tracking(1.2)
                }
                .frame(width: 76, alignment: .leading)

                Rectangle()
                    .fill(Color.moSurface)
                    .frame(width: 1, height: 26)

                // Message
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.moText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Deny → sends "n" to terminal
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

                // Allow → sends "y" to terminal
                Button(action: onAllow) {
                    Text("Allow  \(timeLeft)s")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.moGreen)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.moGreen.opacity(0.13))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
                .keyboardShortcut(.return, modifiers: [.command])
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 60)
        .scaleEffect(visible ? 1.0 : 0.82)
        .opacity(visible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                visible = true
            }
            startTimer()
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timeLeft > 1 {
                timeLeft -= 1
            } else {
                t.invalidate()
                onDeny()
            }
        }
    }
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let message: String

    init(message: String) {
        self.message = message
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

        window = NSPanel(
            contentRect: .init(x: x, y: y, width: w, height: h),
            styleMask:   [.borderless],
            backing:     .buffered,
            defer:       false
        )
        window.level              = NSWindow.Level(rawValue: Int(NSWindow.Level.floating.rawValue) + 1)
        window.backgroundColor    = .clear
        window.isOpaque           = false
        window.hasShadow          = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true

        window.contentView = NSHostingView(rootView: PillView(
            message: message,
            onAllow: {
                sendToGhostty("y") { exit(0) }
            },
            onDeny: {
                sendToGhostty("n") { exit(0) }
            }
        ))

        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Entry point

let inputData = FileHandle.standardInput.readDataToEndOfFile()

var message = "Claude is waiting for your input"
if let p = try? JSONDecoder().decode(NotificationPayload.self, from: inputData) {
    message = p.message ?? p.title ?? message
}

let app      = NSApplication.shared
let delegate = AppDelegate(message: message)
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
