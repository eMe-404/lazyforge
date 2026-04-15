// forge-notify — Dynamic Island-style notification pill for Claude Code
//
// Reads a Claude Code Notification hook JSON payload from stdin.
// Allow (click) → uses Ghostty's AppleScript `focus terminal` to switch to Claude's
//                 exact tab/pane/split, then sends y↵ via TIOCSTI.
// Allow (Return / Cmd+Enter) → sends y↵ to Claude, stays in current app.
// Deny (click) → sends n↵ to Claude, stays in current app.
//
// Window targeting strategy:
//   IDENTIFY — Ghostty AppleScript API: iterate every terminal whose working directory
//              matches savedCWD (Claude Code's project dir, inherited by the hook process).
//              Returns a stable UUID `id` for that terminal surface.
//   FOCUS    — `focus terminal id <uuid>` via AppleScript: Ghostty handles Space switch +
//              window activation + tab switch + split pane focus internally, exactly like
//              its own bell-notification click handler does.
//   FALLBACK — CGSManagedDisplaySetCurrentSpace if no AppleScript match found.
//
// Keystroke delivery: TIOCSTI ioctl to the captured PTY slave path — works regardless of
// which window is focused, always reaches Claude Code's stdin.
//
// Requires Accessibility + Automation (Ghostty) permissions.
//
// Compile:  see install.sh (requires embedding Info.plist)
// Install:  ./install.sh

import Cocoa
import SwiftUI
import ApplicationServices

// MARK: - CGS private API declarations (fallback Space switch only)

typealias CGSConnectionID = Int32
typealias CGSSpaceID      = UInt64

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray?

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
func CGSManagedDisplaySetCurrentSpace(_ cid: CGSConnectionID, _ displayUUID: CFString, _ spaceID: CGSSpaceID)

// MARK: - Input model

struct NotificationPayload: Decodable {
    let message: String?
    let title:   String?
}

// MARK: - Debug log

func fnLog(_ msg: String) {
    let line = msg + "\n"
    if let fh = FileHandle(forWritingAtPath: "/tmp/forge-notify.log") {
        fh.seekToEndOfFile(); fh.write(line.data(using: .utf8)!); fh.closeFile()
    } else {
        FileManager.default.createFile(atPath: "/tmp/forge-notify.log", contents: line.data(using: .utf8))
    }
}

// MARK: - Terminal identification (PTY path)

func ourControllingTTYPath() -> String? {
    for fd in [STDERR_FILENO, STDOUT_FILENO, STDIN_FILENO] {
        if isatty(fd) != 0, let cname = ttyname(fd) {
            let s = String(cString: cname)
            if !s.isEmpty && s != "/dev/tty" { fnLog("tty: found via fd=\(fd) → \(s)"); return s }
        }
    }
    if let path = parentChainTTYPath() { fnLog("tty: found via parent chain → \(path)"); return path }
    let fd = Darwin.open("/dev/tty", O_RDONLY | O_NOCTTY)
    guard fd >= 0 else { fnLog("tty: no controlling terminal"); return nil }
    defer { Darwin.close(fd) }
    if let cname = ttyname(fd) {
        let s = String(cString: cname)
        if !s.isEmpty { fnLog("tty: fallback /dev/tty → \(s)"); return s }
    }
    fnLog("tty: fallback /dev/tty (no ttyname)")
    return "/dev/tty"
}

func parentChainTTYPath() -> String? {
    var selfTTYName = ""
    for fd in [STDERR_FILENO, STDOUT_FILENO, STDIN_FILENO] {
        if isatty(fd) != 0, let cn = ttyname(fd) { selfTTYName = String(cString: cn); break }
    }
    var pid = Int32(getpid())
    var visited = Set<Int32>()
    while pid > 1, !visited.contains(pid) {
        visited.insert(pid)
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var ki = kinfo_proc()
        var sz = MemoryLayout<kinfo_proc>.size
        guard sysctl(&mib, 4, &ki, &sz, nil, 0) == 0 else { break }
        let ppid   = Int32(ki.kp_eproc.e_ppid)
        let ttydev = ki.kp_eproc.e_tdev
        if ttydev != -1, let cn = devname(dev_t(ttydev), S_IFCHR) {
            let path = "/dev/" + String(cString: cn)
            if path != selfTTYName && path != "/dev/tty" { return path }
        }
        pid = ppid
    }
    return nil
}

// MARK: - Ghostty AppleScript terminal targeting

// Finds the Ghostty terminal surface that owns Claude's PTY.
//
// Strategy 1 (TTY marker) — preferred, unambiguous:
//   Write a unique OSC 0 title escape to savedTTY. Ghostty processes it and sets
//   terminal.name to the marker for exactly that surface. Query by that name.
//   Works even when multiple tabs share the same CWD.
//
// Strategy 2 (CWD fallback) — used when no TTY is available (manual test triggers):
//   Traverse window→tab→terminal to find terminals with matching working directory.
//   Returns the parent tab's user-set label (tab.name) for display — not the
//   program title (terminal.name) which can be stale or misleading.
func findGhosttyTerminal(cwd: String, tty: String?) -> (id: String, name: String)? {
    // --- Strategy 1: TTY title marker ---
    if let ttyPath = tty {
        let marker = "forge-notify-\(getpid())"
        let seq    = "\u{1B}]0;\(marker)\u{07}"   // OSC 0: set terminal title
        let bytes  = Array(seq.utf8)
        let fd     = Darwin.open(ttyPath, O_WRONLY | O_NOCTTY)
        if fd >= 0 {
            _ = Darwin.write(fd, bytes, bytes.count)
            Darwin.close(fd)
            Thread.sleep(forTimeInterval: 0.1)  // let Ghostty process the OSC

            let esc = marker.replacingOccurrences(of: "\"", with: "\\\"")
            let src = """
            tell application "Ghostty"
                set US to ASCII character 31
                repeat with w in every window
                    repeat with tb in every tab of w
                        repeat with t in every terminal of tb
                            if name of t is "\(esc)" then
                                return (id of t as text) & US & (name of tb as text)
                            end if
                        end repeat
                    end repeat
                end repeat
                return ""
            end tell
            """
            var err: NSDictionary?
            let raw = NSAppleScript(source: src)?.executeAndReturnError(&err).stringValue ?? ""
            if let e = err { fnLog("findGhosttyTerminal: marker query error: \(e["NSAppleScriptErrorMessage"] ?? e)") }
            if !raw.isEmpty {
                let parts = raw.components(separatedBy: "\u{001F}")
                let tid = parts[0]
                let tab = parts.count > 1 ? parts[1] : ""
                fnLog("findGhosttyTerminal: TTY marker → id=\(tid) tab=\(tab.isEmpty ? "(none)" : tab)")
                return (tid, tab)
            }
            fnLog("findGhosttyTerminal: TTY marker not found in Ghostty, falling back to CWD")
        } else {
            fnLog("findGhosttyTerminal: could not open tty \(ttyPath), falling back to CWD")
        }
    }

    // --- Strategy 2: CWD fallback ---
    let escaped = cwd
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    let src = """
    tell application "Ghostty"
        set targetCWD to "\(escaped)"
        set US to ASCII character 31
        set RS to ASCII character 30
        set out to ""
        repeat with w in every window
            repeat with tb in every tab of w
                repeat with t in every terminal of tb
                    if working directory of t is targetCWD then
                        set out to out & (id of t as text) & US & (name of tb as text) & RS
                    end if
                end repeat
            end repeat
        end repeat
        return out
    end tell
    """
    guard let script = NSAppleScript(source: src) else { fnLog("findGhosttyTerminal: NSAppleScript init failed"); return nil }
    var error: NSDictionary?
    let result = script.executeAndReturnError(&error)
    if let e = error { fnLog("findGhosttyTerminal: CWD query error: \(e["NSAppleScriptErrorMessage"] ?? e)"); return nil }

    let raw = result.stringValue ?? ""
    guard !raw.isEmpty else { fnLog("findGhosttyTerminal: no CWD match for \(cwd)"); return nil }

    let records = raw.components(separatedBy: "\u{001E}").filter { !$0.isEmpty }
    let matches: [(id: String, tabName: String)] = records.compactMap { rec in
        let parts = rec.components(separatedBy: "\u{001F}")
        guard !parts[0].isEmpty else { return nil }
        return (parts[0], parts.count > 1 ? parts[1] : "")
    }
    guard !matches.isEmpty else { fnLog("findGhosttyTerminal: no CWD match for \(cwd)"); return nil }
    for m in matches { fnLog("findGhosttyTerminal: CWD candidate id=\(m.id) tab=\(m.tabName.isEmpty ? "(none)" : m.tabName)") }

    let chosen = matches.first(where: { !$0.tabName.isEmpty }) ?? matches[0]
    fnLog("findGhosttyTerminal: CWD chose id=\(chosen.id) tab=\(chosen.tabName.isEmpty ? "(none)" : chosen.tabName)")
    return (chosen.id, chosen.tabName)
}

// Calls Ghostty's `focus terminal` AppleScript command for the given terminal UUID.
// This brings the correct Space, window, tab, and split pane to the front — the same
// mechanism Ghostty uses internally when the user clicks its own bell notification.
func focusGhosttyTerminal(id termID: String) {
    let escaped = termID
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    let src = """
    tell application "Ghostty"
        try
            focus (first terminal whose id is "\(escaped)")
        end try
    end tell
    """
    var error: NSDictionary?
    NSAppleScript(source: src)?.executeAndReturnError(&error)
    if let e = error { fnLog("focusGhosttyTerminal: error: \(e["NSAppleScriptErrorMessage"] ?? e)") }
    else             { fnLog("focusGhosttyTerminal: focused id=\(termID)") }
}

// MARK: - Space ID helpers (fallback)

func currentSpaceID() -> CGSSpaceID? {
    guard let arr = CGSCopyManagedDisplaySpaces(CGSMainConnectionID()) as? [[String: Any]] else { return nil }
    for disp in arr {
        guard let curDict = disp["Current Space"] as? [String: Any],
              let curID   = curDict["id64"] as? UInt64 else { continue }
        return CGSSpaceID(curID)
    }
    return nil
}

func spaceInfoForTarget(_ targetSID: CGSSpaceID)
    -> (displayID: String, ordered: [CGSSpaceID], current: CGSSpaceID)?
{
    guard let arr = CGSCopyManagedDisplaySpaces(CGSMainConnectionID())
              as? [[String: Any]] else { return nil }
    for disp in arr {
        guard let sArr    = disp["Spaces"]           as? [[String: Any]],
              let curDict = disp["Current Space"]    as? [String: Any],
              let curID   = curDict["id64"]           as? UInt64,
              let dispID  = disp["Display Identifier"] as? String else { continue }
        let ordered = sArr.compactMap { $0["id64"] as? UInt64 }.map { CGSSpaceID($0) }
        if ordered.contains(targetSID) {
            return (dispID, ordered, CGSSpaceID(curID))
        }
    }
    return nil
}

func switchToSpaceViaMissionControl(_ targetSID: CGSSpaceID) -> Bool {
    guard let info = spaceInfoForTarget(targetSID) else {
        fnLog("space-switch: spaceInfoForTarget failed for sid=\(targetSID)"); return false
    }
    fnLog("space-switch: targetSID=\(targetSID) current=\(info.current) display=\(info.displayID)")
    if info.current == targetSID { fnLog("space-switch: already on target Space"); return true }
    CGSManagedDisplaySetCurrentSpace(CGSMainConnectionID(), info.displayID as CFString, targetSID)
    fnLog("space-switch: CGSManagedDisplaySetCurrentSpace called")
    Thread.sleep(forTimeInterval: 0.45)
    fnLog("space-switch: done")
    return true
}

// MARK: - TTY input injection via TIOCSTI

func writeTTY(_ ttyPath: String, key: String) -> Bool {
    let fd = Darwin.open(ttyPath, O_RDWR | O_NOCTTY)
    guard fd >= 0 else { fnLog("writeTTY: open(\(ttyPath)) failed errno=\(errno)"); return false }
    defer { Darwin.close(fd) }
    for ch in (key + "\n").utf8 {
        var c = CChar(bitPattern: ch)
        if Darwin.ioctl(fd, TIOCSTI, &c) != 0 {
            fnLog("writeTTY: TIOCSTI failed errno=\(errno)"); return false
        }
    }
    fnLog("writeTTY: TIOCSTI injected '\(key)\\n' to \(ttyPath)")
    return true
}

// MARK: - Core send helper

func sendToClaudeSession(key: String, tty: String?,
                          termID: String?, targetSpaceID: CGSSpaceID?,
                          switchFocus: Bool,
                          restoreTo: NSRunningApplication? = nil,
                          then done: @escaping () -> Void) {
    let ghosttyApp = NSRunningApplication
        .runningApplications(withBundleIdentifier: "com.mitchellh.ghostty").first
    fnLog("sendToClaudeSession: dispatching (termID=\(termID ?? "nil") spaceID=\(targetSpaceID.map{"\($0)"} ?? "nil") ghostty=\(ghosttyApp != nil) switchFocus=\(switchFocus))")

    DispatchQueue.global(qos: .userInitiated).async {
        fnLog("sendToClaudeSession: async block running")

        func onMain(_ block: @escaping () -> Void) {
            let sem = DispatchSemaphore(value: 0)
            DispatchQueue.main.async { block(); sem.signal() }
            sem.wait()
        }

        if switchFocus {
            if let tid = termID {
                // Primary path: Ghostty's own focus mechanism handles Space+window+tab+pane.
                // Run on main thread because NSAppleScript requires it.
                fnLog("sendToClaudeSession: using AppleScript focus for termID=\(tid)")
                onMain { focusGhosttyTerminal(id: tid) }
                // Brief pause for the Space switch animation to complete.
                Thread.sleep(forTimeInterval: 0.25)
                fnLog("sendToClaudeSession: AppleScript focus complete")
            } else if let sid = targetSpaceID {
                // Fallback: CGS space switch + generic app activate.
                fnLog("sendToClaudeSession: fallback — CGS space switch to sid=\(sid)")
                _ = switchToSpaceViaMissionControl(sid)
                onMain {
                    NSRunningApplication
                        .runningApplications(withBundleIdentifier: "com.mitchellh.ghostty")
                        .first?.activate(options: [])
                }
                fnLog("sendToClaudeSession: fallback complete")
            }
        }

        // Deliver keystroke via TIOCSTI (direct PTY injection — reaches Claude's stdin
        // regardless of which window is currently focused).
        fnLog("sendToClaudeSession: sending keystroke \(key)")
        var sent = false
        if let ttyPath = tty {
            sent = writeTTY(ttyPath, key: key)
        }
        if !sent {
            // AppleScript fallback keystroke: requires Ghostty to be frontmost.
            let keystroke = """
            tell application "System Events"
                keystroke "\(key)"
                key code 36
            end tell
            """
            onMain {
                if let s = NSAppleScript(source: keystroke) { var e: NSDictionary?; s.executeAndReturnError(&e) }
            }
        }
        fnLog("sendToClaudeSession: keystroke sent (tty=\(sent))")

        if let app = restoreTo {
            Thread.sleep(forTimeInterval: 0.05)
            onMain { app.activate(options: []) }
        }

        DispatchQueue.main.async { done() }
    }
}

// MARK: - Named actions (called on main thread)

func allowInGhostty(tty: String?, termID: String?, spaceID: CGSSpaceID?, then done: @escaping () -> Void) {
    fnLog("action: allowInGhostty")
    sendToClaudeSession(key: "y", tty: tty, termID: termID, targetSpaceID: spaceID, switchFocus: true, restoreTo: nil, then: done)
}

func allowSilently(tty: String?, termID: String?, spaceID: CGSSpaceID?, then done: @escaping () -> Void) {
    fnLog("action: allowSilently")
    sendToClaudeSession(key: "y", tty: tty, termID: termID, targetSpaceID: spaceID, switchFocus: false, restoreTo: nil, then: done)
}

func denyInGhostty(tty: String?, termID: String?, spaceID: CGSSpaceID?, then done: @escaping () -> Void) {
    fnLog("action: denyInGhostty")
    sendToClaudeSession(key: "n", tty: tty, termID: termID, targetSpaceID: spaceID, switchFocus: false, restoreTo: nil, then: done)
}

func focusTerminalOnly(termID: String?, spaceID: CGSSpaceID?, then done: @escaping () -> Void) {
    fnLog("action: focusTerminalOnly")
    DispatchQueue.global(qos: .userInitiated).async {
        func onMain(_ block: @escaping () -> Void) {
            let sem = DispatchSemaphore(value: 0)
            DispatchQueue.main.async { block(); sem.signal() }
            sem.wait()
        }
        if let tid = termID {
            onMain { focusGhosttyTerminal(id: tid) }
            Thread.sleep(forTimeInterval: 0.25)
        } else if let sid = spaceID {
            _ = switchToSpaceViaMissionControl(sid)
            onMain {
                NSRunningApplication
                    .runningApplications(withBundleIdentifier: "com.mitchellh.ghostty")
                    .first?.activate(options: [])
            }
        }
        DispatchQueue.main.async { done() }
    }
}

// MARK: - Catppuccin Mocha palette

extension Color {
    static let moBase    = Color(red: 0.118, green: 0.118, blue: 0.180)
    static let moSurface = Color(red: 0.192, green: 0.196, blue: 0.267)
    static let moText    = Color(red: 0.804, green: 0.839, blue: 0.957)
    static let moMauve   = Color(red: 0.796, green: 0.651, blue: 0.969)
    static let moGreen   = Color(red: 0.651, green: 0.890, blue: 0.631)
    static let moRed     = Color(red: 0.953, green: 0.545, blue: 0.659)
    static let moSky     = Color(red: 0.537, green: 0.855, blue: 0.976)
}

// MARK: - Shared badge

private struct ClaudeBadge: View {
    let windowTitle: String?
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text("✦").font(.system(size: 15)).foregroundColor(accentColor)
                Text("CLAUDE")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(accentColor)
                    .tracking(1.2)
            }
            if let title = windowTitle, !title.isEmpty {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.moSky)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(width: 96, alignment: .leading)
    }
}

// MARK: - Approval pill (waiting for input — shows Allow / Deny)

struct ApprovalPillView: View {
    let message:        String
    let windowTitle:    String?
    let onAllowClick:   () -> Void
    let onAllowSilent:  () -> Void
    let onDeny:         () -> Void

    @State private var visible  = false
    @State private var timeLeft = 30

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.moBase)
                .overlay(Capsule().strokeBorder(Color.moSurface, lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 6)

            HStack(spacing: 14) {
                ClaudeBadge(windowTitle: windowTitle, accentColor: .moMauve)

                Rectangle().fill(Color.moSurface).frame(width: 1, height: 32)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.moText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onDeny) {
                    Text("Deny")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.moRed)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Color.moRed.opacity(0.13))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onAllowClick) {
                    Text("Allow  \(timeLeft)s")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.moGreen)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Color.moGreen.opacity(0.13))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Button(action: onAllowSilent) { EmptyView() }
                .frame(width: 0, height: 0).opacity(0)
                .keyboardShortcut(.return, modifiers: [])
                .keyboardShortcut(.return, modifiers: [.command])
        }
        .frame(height: 72)
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
            else { t.invalidate(); exit(0) }
        }
    }
}

// MARK: - Done pill (task completed — click to focus, auto-dismiss in 6 s)

struct DonePillView: View {
    let message:     String
    let windowTitle: String?
    let onFocus:     () -> Void   // click pill body → focus terminal + dismiss

    @State private var visible  = false
    @State private var timeLeft = 6

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.moBase)
                .overlay(Capsule().strokeBorder(Color.moSurface, lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 18, y: 6)

            HStack(spacing: 14) {
                ClaudeBadge(windowTitle: windowTitle, accentColor: .moGreen)

                Rectangle().fill(Color.moSurface).frame(width: 1, height: 32)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.moText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onFocus) {
                    Text("View  \(timeLeft)s")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.moSky)
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Color.moSky.opacity(0.13))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 72)
        .scaleEffect(visible ? 1.0 : 0.82)
        .opacity(visible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) { visible = true }
            NSSound(named: .init("Blow"))?.play()
            startTimer()
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timeLeft > 1 { timeLeft -= 1 }
            else { t.invalidate(); exit(0) }
        }
    }
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let message:           String
    let savedTTY:          String?
    let savedSpaceID:      CGSSpaceID?
    let savedCWD:          String
    var savedTerminalID:   String?
    var savedTerminalName: String?
    var keyMonitor:        Any?

    init(message: String, savedTTY: String?, savedSpaceID: CGSSpaceID?, savedCWD: String) {
        self.message      = message
        self.savedTTY     = savedTTY
        self.savedSpaceID = savedSpaceID
        self.savedCWD     = savedCWD
    }

    func applicationDidFinishLaunching(_: Notification) {
        // Run loop is active — AppleScript and AX queries work here.
        // Find Claude's specific Ghostty terminal surface by matching working directory.
        if let match = findGhosttyTerminal(cwd: savedCWD, tty: savedTTY) {
            savedTerminalID   = match.id
            savedTerminalName = match.name.isEmpty ? nil : match.name
        }
        fnLog("appLaunched: termID=\(savedTerminalID ?? "(none)") name=\(savedTerminalName ?? "(none)")")

        let screen = NSScreen.screens.first(where: {
            NSMouseInRect(NSEvent.mouseLocation, $0.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.visibleFrame

        let w: CGFloat = 580
        let h: CGFloat = 72
        let x = frame.minX + (frame.width - w) / 2
        let y = frame.maxY - h - 8

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

        let tty   = savedTTY
        let tid   = savedTerminalID
        let sid   = savedSpaceID
        let tname = savedTerminalName

        // Route to the right pill based on message content.
        // "waiting" in the message → approval needed (show Allow/Deny).
        // Anything else (task done, agent finished, etc.) → done pill (click to focus).
        let isApproval = message.lowercased().contains("waiting")
        fnLog("appLaunched: isApproval=\(isApproval) message=\(message)")

        if isApproval {
            window.contentView = NSHostingView(rootView: ApprovalPillView(
                message:       message,
                windowTitle:   tname,
                onAllowClick:  { allowInGhostty(tty: tty, termID: tid, spaceID: sid) { exit(0) } },
                onAllowSilent: { allowSilently(tty: tty, termID: tid, spaceID: sid)  { exit(0) } },
                onDeny:        { denyInGhostty(tty: tty, termID: tid, spaceID: sid)  { exit(0) } }
            ))
            // Return/Cmd+Enter → allow silently from keyboard
            keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return }
                if event.keyCode == 36 {
                    if let m = self.keyMonitor { NSEvent.removeMonitor(m); self.keyMonitor = nil }
                    allowSilently(tty: self.savedTTY, termID: self.savedTerminalID, spaceID: self.savedSpaceID) { exit(0) }
                }
            }
        } else {
            window.contentView = NSHostingView(rootView: DonePillView(
                message:     message,
                windowTitle: tname,
                onFocus:     { focusTerminalOnly(termID: tid, spaceID: sid) { exit(0) } }
            ))
        }

        window.orderFrontRegardless()
    }
}

// MARK: - Entry point

let inputData = FileHandle.standardInput.readDataToEndOfFile()

var message = "Claude is waiting for your input"
if let p = try? JSONDecoder().decode(NotificationPayload.self, from: inputData) {
    message = p.message ?? p.title ?? message
}

let savedTTY     = ourControllingTTYPath()
let savedSpaceID = currentSpaceID()
let savedCWD     = FileManager.default.currentDirectoryPath

fnLog("startup: spaceID=\(savedSpaceID.map{"\($0)"} ?? "nil") tty=\(savedTTY ?? "(none)") cwd=\(savedCWD)")

let app      = NSApplication.shared
let delegate = AppDelegate(message: message, savedTTY: savedTTY, savedSpaceID: savedSpaceID, savedCWD: savedCWD)
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
