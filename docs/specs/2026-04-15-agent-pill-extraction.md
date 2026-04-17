# agent-pill — Standalone Project Extraction Spec

**Date:** 2026-04-15
**Status:** Approved, awaiting implementation

---

## What We're Building

Extract `forge-notify` from `yaer-forge` into a standalone project called **`agent-pill`** — a Dynamic Island-style notification pill for AI coding agent CLIs. It surfaces permission approvals and task completions as a floating HUD, letting users approve without leaving their current window or jump back to the right terminal tab with one keystroke.

---

## Decisions

| Question | Decision |
|---|---|
| Name | `agent-pill` |
| Terminal scope | Ghostty-only for v1 |
| LLM tool scope | Claude Code-first; config-driven for future tools |
| Install | Script-only now → Homebrew tap at public launch |
| License | MIT |

---

## Repo Structure

```
agent-pill/
├── Sources/
│   ├── main.swift                        # entry point only
│   ├── AppDelegate.swift                 # window lifecycle
│   ├── Config/
│   │   ├── Config.swift                  # load + merge user config
│   │   └── Defaults.swift               # built-in defaults (Claude Code / Ghostty)
│   ├── Router/
│   │   └── NotificationRouter.swift      # classify payload → pill type + display message
│   ├── Terminal/
│   │   ├── TerminalAdapter.swift         # protocol: find(cwd:tty:) + focus(id:)
│   │   ├── Ghostty/
│   │   │   ├── GhosttyFinder.swift       # TTY marker + CWD AppleScript queries
│   │   │   └── GhosttyFocus.swift        # `focus terminal id` AppleScript
│   │   ├── TTYInjector.swift             # TIOCSTI keystroke injection (shared)
│   │   └── SpaceSwitcher.swift           # CGS fallback space switch (shared)
│   └── UI/
│       ├── ApprovalPillView.swift
│       ├── DonePillView.swift
│       └── Components/
│           ├── ClaudeBadge.swift
│           └── Theme.swift               # Catppuccin palette + shared styles
├── hooks/
│   ├── claude-code.json                  # ready-to-merge hook config
│   └── opencode.json                     # placeholder for future
├── Info.plist
├── config.example.json
├── install.sh
├── uninstall.sh
├── LICENSE
└── README.md
```

**Build:** `swiftc $(find Sources -name "*.swift" | sort) ...` — no build system, same approach as today.

---

## Extensibility Axes

### Terminal adapters
`TerminalAdapter` is a Swift protocol with two methods: `find(cwd:tty:) -> (id: String, name: String)?` and `focus(id:)`. Adding iTerm2 support means creating `Sources/Terminal/iTerm2/` and conforming to the protocol — nothing else changes.

### LLM tool routing
`NotificationRouter` owns all "which pill?" classification logic. Changing routing for OpenCode means editing one file and/or updating the user's config.

### Config
User overrides in `~/.config/agent-pill/config.json` compose on top of `Defaults.swift`. The rest of the code never touches JSON.

---

## Config System

File: `~/.config/agent-pill/config.json` (optional — defaults work out of the box)

```json
{
  "terminal": "ghostty",

  "routing": {
    "approval_patterns": ["permission"],
    "completion_replace": {
      "waiting for your input": "Task completed"
    }
  },

  "approval": {
    "allow_key": "y",
    "deny_key": "n",
    "timeout_seconds": 30
  },

  "done": {
    "timeout_seconds": 6
  }
}
```

**Hardcoded in v1 (not configurable):**
- Pill UI size, position, Catppuccin theme
- Keyboard shortcut `Cmd+Shift+A`
- Install path `~/.local/bin/agent-pill`

---

## README Structure

```
# agent-pill

[GIF of both pills in action — required before public launch]

One-line description.

## Requirements
## Install
## Usage
## Configuration
## Uninstall
## License
```

Two assets required before going public:
1. **GIF/screenshot** at the top — without it nobody understands the project from the description
2. **ARCHITECTURE.md** — explains TTY marker strategy, why AppleScript over CGS/AX, how keystroke injection works

---

## Versioning & Release Strategy

**Private phase:**
- Start at `v0.1.0`
- Tag meaningful milestones: `v0.2.0` (config system), `v0.3.0` (Homebrew tap setup)
- No GitHub Releases yet — git tags only

**Public launch:**
- Cut `v1.0.0` as first public release
- GitHub Release with changelog + GIF
- Homebrew tap: `github.com/<owner>/homebrew-agent-pill`
  - `brew tap <owner>/agent-pill && brew install agent-pill`

**Commit convention:** `feat:`, `fix:`, `docs:`, `chore:` prefixes (consistent with yaer-forge)

---

## Public Launch Checklist

### Code cleanup
- [ ] Rename all `forge-notify` → `agent-pill` (binary name, log path, bundle ID, internal strings)
- [ ] Split `forge-notify.swift` into layered `Sources/` structure
- [ ] Implement `Config` loader with fallback to `Defaults`
- [ ] Wire `TerminalAdapter` protocol — `GhosttyFinder` + `GhosttyFocus` conform to it
- [ ] Update `Info.plist` bundle ID to `dev.agentpill.agent-pill`
- [ ] Update `hooks/claude-code.json` command path to `agent-pill`

### Repo hygiene
- [ ] `LICENSE` (MIT)
- [ ] `README.md` with GIF/screenshot
- [ ] `ARCHITECTURE.md`
- [ ] `.gitignore`

### Validation
- [ ] Clean install test (no yaer-forge, fresh directory)
- [ ] `uninstall.sh` leaves no traces
- [ ] Both pills work end-to-end

### Launch
- [ ] Create Homebrew tap repo
- [ ] Tag `v1.0.0`
- [ ] GitHub Release with GIF + changelog
