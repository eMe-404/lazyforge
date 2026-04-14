// forge-notify — Dynamic Island-style notification pill for Claude Code
//
// Reads a Claude Code Notification hook JSON payload from stdin.
// Displays a floating pill at the top of the screen and auto-dismisses.
// Exits 0 always (notifications are informational, not gating).
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

// MARK: - Catppuccin Mocha palette

extension Color {
    static let moBase    = Color(red: 0.118, green: 0.118, blue: 0.180) // #1e1e2e
    static let moSurface = Color(red: 0.192, green: 0.196, blue: 0.267) // #313244
    static let moText    = Color(red: 0.804, green: 0.839, blue: 0.957) // #cdd6f4
    static let moMauve   = Color(red: 0.796, green: 0.651, blue: 0.969) // #cba6f7
    static let moGreen   = Color(red: 0.651, green: 0.890, blue: 0.631) // #a6e3a1
    static let moSubtext = Color(red: 0.651, green: 0.678, blue: 0.784) // #a6adc8
}

// MARK: - Pill view

struct PillView: View {
    let message: String
    let onDismiss: () -> Void

    @State private var visible  = false
    @State private var timeLeft = 8

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.moBase)
                .overlay(Capsule().strokeBorder(Color.moSurface, lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 6)

            HStack(spacing: 12) {
                // Claude indicator
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

                // Notification message
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.moText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Dismiss
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.moSubtext)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.moSurface.opacity(0.6))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
                .keyboardShortcut(.escape, modifiers: [])
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
                withAnimation(.easeOut(duration: 0.3)) { visible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDismiss() }
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

        let w: CGFloat = 480
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
            message:   message,
            onDismiss: { exit(0) }
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
// stdin read before app.run() so the main run loop is never blocked.

let inputData = FileHandle.standardInput.readDataToEndOfFile()

var message = "Claude needs your attention"
if let p = try? JSONDecoder().decode(NotificationPayload.self, from: inputData) {
    message = p.message ?? p.title ?? message
}

let app      = NSApplication.shared
let delegate = AppDelegate(message: message)
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
