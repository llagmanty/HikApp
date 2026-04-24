import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingActiveHike = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            heroSection
            Spacer()
            bottomSection
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .fullScreenCover(isPresented: $showingActiveHike) {
            ActiveHikeView()
                .environmentObject(locationManager)
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                showingActiveHike = true
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 88))
                .foregroundStyle(.green)

            Text("HikApp")
                .font(.system(size: 42, weight: .heavy, design: .rounded))

            Text("Track your hike.\nReview your stats.\nLeave no trace.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal)
    }

    private var bottomSection: some View {
        VStack(spacing: 14) {
            privacyBadge
            startButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
    }

    private var startButton: some View {
        Button(action: handleStart) {
            Label("Start Hike", systemImage: "play.fill")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
        }
    }

    private var privacyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)
            Text("No login · No cloud · Session data deleted on exit")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
    }

    private func handleStart() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()
        case .denied, .restricted:
            // System will surface the Settings prompt if needed
            break
        default:
            showingActiveHike = true
        }
    }
}
