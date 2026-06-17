# CLAUDE.md

Guidance for working in this repository with Claude Code (and any future agent).

## What this is

AspectShot — a macOS 14+ agent-style app (`LSUIElement`, no Dock icon) that captures an
aspect-ratio-locked (default 16:9) region of the screen via ScreenCaptureKit and saves it to
`~/Downloads`. See `README.md` for the user-facing description.

## Module boundaries (respect these)

- **`AspectShotKit/`** — a static library holding all *pure, deterministic* logic. No AppKit,
  no SwiftUI views, no ScreenCaptureKit. This is where new business logic and its tests go.
  - `AspectGeometry` — aspect-lock + bounds-clamp math (stateless).
  - `SelectionModel` — `@MainActor` observable state machine; delegates math to `AspectGeometry`.
  - `CropGeometry` — point-rect → integral pixel-rect crop math.
  - `ScreenshotNaming` — output filename (`timeZone` is injectable for testing).
  - `CaptureCoordinator` — capture sequencing (`prepare → capture → success/failure`) + the
    reentrancy guard. Side effects are injected so the sequence is unit-tested without AppKit.
  - `Config`, `Corner` — tunables and the corner enum.
- **`AspectShot/`** — the thin AppKit/SwiftUI shell. AppKit windows, SwiftUI overlay, the
  ScreenCaptureKit/ImageIO calls, permission prompts. Keep logic here minimal; push anything
  testable down into the Kit.
- **`AspectShotKitTests/`** — XCTest target for the Kit. It depends on the Kit only (no
  `TEST_HOST`), so it runs headlessly.

## Build & test

The `xcrun`/`swift` cache writes hit the command sandbox, so build/test commands here are run
with the sandbox disabled. Signing is skipped for command-line builds.

```bash
# Build the app
xcodebuild build -project AspectShot.xcodeproj -scheme AspectShot -configuration Debug \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO

# Run the unit tests (this is the gate that runs in CI / headless)
xcodebuild test -project AspectShot.xcodeproj -scheme AspectShotKitTests \
  -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
```

## Workflow expectations

- **Test-driven: Red → Green → Refactor.** Write a failing test in `AspectShotKitTests/` first,
  watch it fail, implement to green, then refactor. Logic that can't be expressed as a Kit unit
  test usually belongs in the app shell — but consider whether it can be extracted to the Kit
  (as `CaptureCoordinator` was) so it *can* be tested.
- **Refactor reviews use two subagents** — a Swift/macOS specialist and an SVP-level engineer —
  run read-only, with the findings applied by the main session. (See `.claude/agents/` and the
  `refactor` skill in `.claude/skills/` once added.)

## Invariants & gotchas

- **Coordinate system:** SwiftUI overlay points, `SelectionModel.rect`, and the captured
  `CGImage` are all **top-left origin**. The crop is `rect * scale` with **no Y-flip**. Don't
  introduce AppKit's bottom-left global coordinates into the capture math.
- **Capture strategy:** capture the *full display* (excluding our overlay windows via
  `SCContentFilter(display:excludingWindows:)`) and crop the `CGImage`. Do **not** switch to
  `SCStreamConfiguration.sourceRect` — its points-vs-pixels meaning has drifted across OS
  versions, and the GUI path can't be verified headlessly.
- **Per-display isolation:** one `OverlayPanel` + `SelectionModel` per `NSScreen`; capture uses
  that display's `displayID` and `backingScaleFactor`. This is why no global coordinate
  conversion is needed.
- **Project files:** the Xcode project uses **file-system-synchronized groups**
  (`objectVersion = 77`). Adding a `.swift` file to a target's folder includes it automatically —
  no `project.pbxproj` editing required. New top-level folders/targets *do* require project edits.
- **Info.plist** keys use build-setting substitution (e.g. `$(PRODUCT_BUNDLE_IDENTIFIER)`);
  `GENERATE_INFOPLIST_FILE = NO`. Keep `CFBundleIdentifier` et al. present.
- **App Sandbox is intentionally OFF**; Screen Recording is gated by TCC at runtime.

## What can't be verified here

The GUI, the TCC permission prompt, on-screen crop alignment, output resolution, and multi-display
behavior cannot be exercised headlessly. Compilation + the Kit unit tests are the automated gate;
the capture path needs a manual run in Xcode to confirm.
