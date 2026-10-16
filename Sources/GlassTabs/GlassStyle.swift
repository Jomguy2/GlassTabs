import SwiftUI

/// Shared Liquid-Glass styling. iOS 26+ gets real Liquid Glass via
/// `.glassEffect`; older systems fall back to ultra-thin material so the
/// app still looks like glass everywhere.
struct GlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.28),
                    Color(red: 0.08, green: 0.28, blue: 0.38),
                    Color(red: 0.12, green: 0.10, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.cyan.opacity(0.25))
                .frame(width: 320, height: 320)
                .offset(x: -140, y: -220)
                .blur(radius: 40)
            Circle()
                .fill(Color.purple.opacity(0.30))
                .frame(width: 360, height: 360)
                .offset(x: 150, y: 240)
                .blur(radius: 50)
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: -140)
                .blur(radius: 30)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Frosted-glass card surface used across all three tabs.
    @ViewBuilder
    func liquidGlassCard(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Full-screen glass backdrop for a tab.
    func glassBackdrop() -> some View {
        ZStack {
            GlassBackground()
            self
        }
    }

    /// Big readable tabular digits for timers.
    func bigDigits(_ size: CGFloat = 64) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
    }
}
