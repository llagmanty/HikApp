import SwiftUI

struct WelcomeView: View {
    let onFinish: () -> Void

    private let duration: Double = 5
    @State private var progress: Double = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Spacer()
                hero
                Spacer()
                footer
            }
        }
        .ignoresSafeArea()
        .onTapGesture { onFinish() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.linear(duration: duration)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { onFinish() }
        }
    }

    // MARK: - Layers

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.36, blue: 0.18),
                     Color(red: 0.04, green: 0.20, blue: 0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var hero: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 100, weight: .thin))
                .foregroundStyle(.white.opacity(0.95))
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text("HikApp")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Track your hike.\nLeave no trace.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(appeared ? 1 : 0)

            HStack(spacing: 20) {
                badge(icon: "lock.shield.fill", text: "No login")
                badge(icon: "icloud.slash.fill",  text: "No cloud")
                badge(icon: "trash.fill",          text: "Auto-delete")
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 32)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text("Tap anywhere to continue")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 3)
                    Capsule()
                        .fill(.white.opacity(0.8))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 52)
    }

    private func badge(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
            Text(text)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

#Preview {
    WelcomeView { }
}
