# AspectShot

A small native macOS app for taking **aspect-ratio-locked screenshots**. Drag a 16:9 frame over a dimmed full-screen overlay, fine-tune it with corner handles or by dragging, then click the floating shutter button — the framed region is captured and saved straight to your Downloads folder.

> アスペクト比（デフォルト 16:9）を固定したまま画面の任意の範囲を選択・微調整し、ダウンロードフォルダに直接保存する macOS ネイティブアプリです。

---

## Features

- **Aspect-ratio-locked selection.** Rubber-band a frame that always keeps a 16:9 ratio.
- **Fine adjustment.** Drag the four corner handles to resize (aspect stays locked), or drag the interior to reposition.
- **Floating shutter.** A translucent round shutter button sits at the frame's center and follows it.
- **Clean capture.** The overlay UI (dimming, frame, handles, shutter) is excluded from the shot.
- **Direct save.** Writes `~/Downloads/ScreenShot_yyyyMMdd_HHmmss.png`, then quits.
- **Multi-display aware.** Each display gets its own overlay; capture uses that display's native resolution.
- **Menu-bar-free.** Runs as an agent app (`LSUIElement`) — no Dock icon, no window chrome.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 26 or later (to build)
- **Screen Recording permission** (macOS prompts on first capture; see below)

## Build & run

```bash
open AspectShot.xcodeproj    # then select the "AspectShot" scheme and Run (⌘R)
```

Or from the command line:

```bash
xcodebuild build -project AspectShot.xcodeproj -scheme AspectShot -configuration Debug
```

### Screen Recording permission

ScreenCaptureKit requires the **Screen Recording** privacy permission.

1. On first launch you'll be guided to **System Settings → Privacy & Security → Screen Recording**.
2. Enable **AspectShot**.
3. **Relaunch the app** — macOS only applies the grant on the next launch.

## Usage

1. Launch the app — the screen dims with a translucent overlay.
2. **Drag** to draw a 16:9 frame.
3. Adjust: drag a **corner handle** to resize (aspect-locked), or drag **inside** the frame to move it.
4. Press **Esc** to clear the selection and start over; press **Esc** again with nothing selected to quit.
5. Click the **shutter button** at the center to capture. The image is saved to `~/Downloads` and the app exits.

## Changing the aspect ratio

The locked ratio (and other tunables: minimum size, dimming, handle/shutter sizes) live in
[`AspectShotKit/Config.swift`](AspectShotKit/Config.swift). Change `aspectWidth` / `aspectHeight`
and rebuild.

## Architecture

The project is split so the testable logic has no UI/AppKit dependency:

| Target | Kind | Contents |
|---|---|---|
| `AspectShotKit` | static library | Pure, unit-tested logic: `AspectGeometry` (aspect-lock + clamp math), `SelectionModel` (state machine), `CropGeometry` (point→pixel crop), `ScreenshotNaming` (filename), `CaptureCoordinator` (capture sequencing + reentrancy guard), `Config`, `Corner`. |
| `AspectShot` | app | Thin AppKit/SwiftUI shell: `OverlayController`, `OverlayPanel`, `OverlayView`, `ShutterButton`, `ScreenCaptureService`, `ImageSaver`, `PermissionManager`, `AppDelegate`. |
| `AspectShotKitTests` | unit tests | XCTest coverage of the Kit. |

**Coordinate-system invariant:** SwiftUI overlay points, the `SelectionModel` rect, and the
captured `CGImage` are all **top-left origin**, so the crop is a straight `rect * scale` with no
Y-flip. The full display is captured (excluding our overlay windows) and then cropped in pixel
space — deterministic and reviewable — rather than relying on `SCStreamConfiguration.sourceRect`.

## Testing

The pure logic is covered by unit tests (the GUI/capture path can't run headlessly):

```bash
xcodebuild test -project AspectShot.xcodeproj -scheme AspectShotKitTests -destination 'platform=macOS'
```

## Known limitations / roadmap

- **Distribution requires signing.** The app builds with automatic signing for local use. To share
  it, set up Developer ID signing + notarization — otherwise the Screen Recording grant breaks on
  every rebuild (TCC keys the grant to the signature).
- **No app icon yet** (ships with the generic icon, which also shows in the permission list).
- **Single-display selection.** A selection lives on one display at a time (by design).
- **Same-second filenames** would overwrite; add a uniquing suffix if that matters to you.
- **Japanese-only UI strings** in the permission/error dialogs.
- **App Sandbox is intentionally off** — a Developer-ID utility needs unsandboxed `~/Downloads`
  access, and Screen Recording is gated by TCC at runtime, not by an entitlement.

## Project notes

- The Xcode project uses **file-system-synchronized groups**, so new `.swift` files added to a
  target's folder are picked up automatically — no `project.pbxproj` edits needed.
- Built test-first (Red → Green → Refactor).
