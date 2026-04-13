---
name: elements-of-style
description: "Apply Strunk & White clarity principles to written documents — spec docs, design docs, READMEs, and any prose you produce. Tightens writing by eliminating weak constructions, redundancy, and vague language."
---

# Writing Clearly and Concisely

Apply these rules when writing or reviewing any prose: spec docs, design docs, commit messages, READMEs, comments. The goal is writing that is immediately understood — nothing surplus, nothing ambiguous.

## The Core Rules

**Omit needless words.**
Every word should do work. Cut phrases that add length without meaning.

| Wordy | Tight |
|-------|-------|
| due to the fact that | because |
| in order to | to |
| it is important to note that | (cut it) |
| at this point in time | now |
| in the event that | if |
| for the purpose of | for |
| with regard to | about |

**Use active voice.**
Active voice is shorter and clearer. Passive voice hides the actor.

| Passive | Active |
|---------|--------|
| The config is loaded by the server | The server loads the config |
| Errors will be logged | The system logs errors |
| It was decided that | We decided |

**Prefer specific to general.**
Vague language makes requirements unverifiable. Name the thing.

| Vague | Specific |
|-------|----------|
| handle errors appropriately | return HTTP 400 with a JSON error body |
| the system should be fast | p99 latency under 200ms |
| store user data securely | encrypt at rest with AES-256 |

**Put statements in positive form.**
Avoid "not" constructions — they make readers work harder.

| Negative | Positive |
|----------|----------|
| do not ignore errors | handle every error |
| not unless | only if |
| was not present | was absent |

**Keep related words together.**
Modifiers should be next to what they modify. Misplaced modifiers create ambiguity.

**One idea per sentence.**
Long sentences with multiple clauses obscure the main point. Split them.

## For Spec Documents Specifically

- **Lead with what, not how.** Requirements describe outcomes, not implementations.
- **Avoid weasel words:** "should", "may", "could", "might" — use "must", "does", or cut the requirement.
- **No implicit actors.** Every sentence should be clear about who or what does the action.
- **No orphaned sections.** Every heading should have content that justifies its existence.

## How to Apply This Skill

When invoked on a document:

1. Read the full document first
2. Flag sentences that violate the rules above
3. Rewrite flagged sentences — one at a time, showing before/after
4. Ask the user to approve each rewrite or offer an alternative
5. Do not change technical content — only tighten the language

When used inline (e.g., after writing a spec):

- Self-apply: read your own output, cut every needless word, switch passive to active
- Flag anything you're uncertain about rather than silently changing technical decisions
