import SwiftUI
import AspectShotKit

/// The floating, semi-transparent circular shutter button shown at the crop frame's center.
struct ShutterButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white.opacity(isHovering ? 0.95 : 0.8))
                Circle()
                    .strokeBorder(.black.opacity(0.15), lineWidth: 1)
                Image(systemName: "camera.fill")
                    .font(.system(size: Config.shutterDiameter * 0.42, weight: .medium))
                    .foregroundStyle(.black.opacity(0.75))
            }
            .frame(width: Config.shutterDiameter, height: Config.shutterDiameter)
            .scaleEffect(isHovering ? 1.08 : 1.0)
            .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .help("この範囲を撮影")
    }
}
