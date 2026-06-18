---
name: refactor
description: Run the two-reviewer refactor pass on recent changes — a Swift/macOS specialist and an SVP-level engineer review read-only, then the high-value findings are applied test-first while keeping the suite green. Use when asked to "refactor", do a review-and-cleanup pass, or harden code after a feature lands.
---

# Refactor (two-reviewer pass)

A disciplined Red/Green/**Refactor** step: get two independent senior perspectives, then apply the
worthwhile findings without breaking anything. The reviewers are **read-only**; the main session
applies the changes so they stay coherent and conflict-free.

## Steps

### 1. Establish a green baseline
Before reviewing, confirm the current state builds and tests pass, so any regression introduced by
the refactor is attributable.

```bash
xcodebuild test -project AspectShot.xcodeproj -scheme AspectShotKitTests \
  -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
xcodebuild build -project AspectShot.xcodeproj -scheme AspectShot -configuration Debug \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO
```

If it isn't green, stop and fix that first — don't refactor on a red baseline.

### 2. Scope what to review
Determine the change set (e.g. `git diff`, recently edited files, or a feature area). Summarize it
so the reviewers focus there rather than the whole tree.

### 3. Launch both reviewers in parallel (read-only)
Use the `Agent` tool **twice in one message** so they run concurrently:

- `subagent_type: "swift-specialist"` — correctness bugs, API misuse, concurrency/memory, Swift/
  SwiftUI/AppKit idiom.
- `subagent_type: "svp-engineer"` — architecture/boundaries, spec completeness, ranked risks,
  testability gaps, project hygiene.

Give each agent: the project layout, the change set / files to focus on, how to build & test, and
which behavior **cannot** be verified in this environment (the GUI/capture/permission path). Tell
them not to edit files — they return reports only.

### 4. Triage the findings
Merge both reports and sort:
- **Apply now:** real bugs and low-risk, high-value improvements (including testability extractions).
- **Defer (document):** distribution/signing, icons, broad rewrites, anything out of scope — record
  these in `README.md` "Known limitations" and/or `CLAUDE.md` rather than implementing.
- **Reject:** conventional defaults flagged as defects, or changes that add risk without payoff.

State your triage briefly before editing.

### 5. Apply test-first
For any change that alters logic in `AspectShotKit`, write/extend a failing test first
(Red → Green). For changes confined to the app shell, rely on the build plus careful review (the
GUI can't run headlessly). Prefer **extracting untestable logic into the Kit** so it can be
covered — that is itself a high-value refactor.

### 6. Re-verify and summarize
Re-run the commands from step 1; confirm green. Then report: what was applied, what was deferred
(and where it's documented), and what still needs a manual run in Xcode to verify.

## Principles
- The reviewers advise; the main session decides and edits.
- Never break the green suite. Every applied change ends with tests passing.
- Be honest about the verification boundary — compilation + Kit unit tests are the automated gate;
  the capture path needs a human run.
