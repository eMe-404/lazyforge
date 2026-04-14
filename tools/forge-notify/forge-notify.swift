// forge-notify — Dynamic Island-style permission overlay for Claude Code
//
// Reads a Claude Code PreToolUse JSON payload from stdin.
// Displays a floating pill at the top of the screen with Allow / Deny buttons.
// Exits 0 (allow) or 2 (deny).
//
// Compile:  see install.sh (requires embedding Info.plist)
// Install:  ./install.sh

import Cocoa
import SwiftUI

// MARK: - Input model

struct HookPayload: Decodable {
    let toolName: String
    let toolInput: ToolInput
    enum CodingKeys: String, CodingKey {
        case toolName = "tool_name"
        case toolInput = "tool_input"
    }
}

struct ToolInput: Decodable {
    let command:  String?
    let filePath: String?
    enum CodingKeys: String, CodingKey {
        case command
        case filePath = "file_path"
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
    let toolName: String
    let detail:   String
    let onAllow:  () -> Void
    let onDeny:   () -> Void

    @State private var timeLeft = 30
    @State private var visible  = false

    private var icon: String {
        switch toolName {
        case "Bash":   return "⚡"
        case "Edit":   return "✏️"
        case "Write":  return "📝"
        case "Read":   return "👁"
        case "Glob":   return "🔍"
        case "Grep":   return "🔎"
        default:       return "🔧"
        }
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.moBase)
                .overlay(Capsule().strokeBorder(Color.moSurface, lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 6)

            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Text(icon).font(.system(size: 15))
                    Text(toolName.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.moMauve)
                        .tracking(1.2)
                }
                .frame(width: 76, alignment: .leading)

                Rectangle()
                    .fill(Color.moSurface)
                    .frame(width: 1, height: 26)

                Text(detail.isEmpty ? "—" : detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.moText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

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
    let toolName: String
    let detail: String

    init(toolName: String, detail: String) {
        self.toolName = toolName
        self.detail   = detail
    }

    func applicationDidFinishLaunching(_: Notification) {
        // No blocking calls here — stdin was already read before app.run()

        // Use the screen the mouse cursor is on so it appears on the right monitor
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
                     ?? NSScreen.main
                     ?? NSScreen.screens[0]
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
        // One level above .floating so it clears other floating panels
        window.level              = NSWindow.Level(rawValue: Int(NSWindow.Level.floating.rawValue) + 1)
        window.backgroundColor    = .clear
        window.isOpaque           = false
        window.hasShadow          = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true

        window.contentView = NSHostingView(rootView: PillView(
            toolName: toolName,
            detail:   String(detail.prefix(80)),
            onAllow:  { exit(0) },
            onDeny:   { exit(2) }
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
// stdin is read HERE, before app.run(), so the main run loop is never blocked.

let inputData = FileHandle.standardInput.readDataToEndOfFile()

var toolName = "Tool"
var detail   = ""
if let p = try? JSONDecoder().decode(HookPayload.self, from: inputData) {
    toolName = p.toolName
    detail   = p.toolInput.command ?? p.toolInput.filePath ?? ""
}

let app      = NSApplication.shared
let delegate = AppDelegate(toolName: toolName, detail: detail)
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
