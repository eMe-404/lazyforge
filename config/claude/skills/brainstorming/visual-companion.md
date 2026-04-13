# Visual Companion Guide

This guide is read by Claude when the user accepts the Visual Companion offer during brainstorming.

## What It Is

A local browser-based companion that displays interactive mockups, diagrams, and visual explorations. Claude writes HTML files to a watched directory; the browser auto-refreshes and captures user interactions (clicks, form inputs) as JSON events that Claude reads each turn.

## When to Use Browser vs Terminal

Use the browser for:
- UI layouts and component mockups
- Architecture diagrams and data flow charts
- Side-by-side option comparisons
- Anything the user needs to click or interact with

Use the terminal for:
- Requirements and constraints discussion
- Trade-off analysis in text
- Code snippets and config examples
- Anything that reads fine as prose

Don't force everything into the browser. Per-question decision: would a visual genuinely help here?

## Starting a Session

If `scripts/start-server.sh` exists in the project:
```bash
./scripts/start-server.sh
```

This starts a local server that:
- Watches a temp directory for new `.html` files
- Serves the newest file at `http://localhost:7777`
- Writes user interaction events to `events.jsonl`

If the script is not present, degrade gracefully — use the browser tool directly to open a data URL, or offer to continue text-only.

## The Loop

Each turn:
1. Write an HTML file to the watched directory (or use browser tool)
2. Tell the user: "I've updated the visual — take a look and interact with it, then tell me what you think or click an option"
3. Next turn: read `events.jsonl` to see what the user clicked/typed
4. Incorporate their choices into the next question or design step

## HTML Content Classes

Use these CSS classes for consistent, readable visuals:

| Class | Use for |
|-------|---------|
| `.options` | List of choices for the user to pick from |
| `.cards` | Feature or component cards laid out in a grid |
| `.mockup` | UI wireframe area |
| `.split` | Two-column side-by-side comparison |
| `.pros-cons` | Pros/cons table for a design trade-off |

Keep HTML minimal — focus on the content, not styling. A clean, readable layout is more useful than a polished one.

## Browser Events Format

Events are written as JSON lines to `events.jsonl`:

```json
{"type": "click", "target": "option-1", "label": "REST API", "ts": 1234567890}
{"type": "input", "target": "notes", "value": "needs auth", "ts": 1234567891}
```

Read the file each turn and incorporate the user's choices. Clear the file after reading to avoid replaying old events.

## Degrading Gracefully

If the browser tool is unavailable or the server isn't running:
- Continue text-only without mentioning the Visual Companion again
- Do not block the brainstorming flow waiting for setup
- Offer to revisit visuals later if the user wants to set it up
