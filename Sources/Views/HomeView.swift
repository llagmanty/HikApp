import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var weatherManager: WeatherManager
    @State private var showingActiveHike = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Blurred map fills the whole screen
            HomeMapBackground(coordinate: locationManager.currentLocation?.coordinate)
                .ignoresSafeArea()
                .blur(radius: 4)

            // Controls sit on a solid surface at the bottom
            bottomSection
        }
        .overlay(alignment: .topTrailing) {
            WeatherWidget(
                temperature: weatherManager.temperature,
                symbolName: weatherManager.symbolName,
                isFetching: weatherManager.isFetching
            )
            .padding(.trailing, 20)
            .padding(.top, 60)
            .opacity(weatherManager.temperature != nil || weatherManager.isFetching ? 1 : 0)
        }
        .task(id: locationManager.currentLocation) {
            guard let loc = locationManager.currentLocation else { return }
            await weatherManager.fetchIfNeeded(for: loc)
        }
        .fullScreenCover(isPresented: $showingActiveHike) {
            ActiveHikeView()
                .environmentObject(locationManager)
                .environmentObject(healthKitManager)
                .environmentObject(weatherManager)
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                showingActiveHike = true
            }
        }
    }

    // MARK: - Bottom

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
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.35), radius: 10, y: 5)
        }
    }

    private var privacyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.accentColor)
            Text("No login · No cloud · Session data deleted on exit")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    // MARK: - Actions

    private func handleStart() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()
        case .denied, .restricted:
            break
        default:
            showingActiveHike = true
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(LocationManager())
        .environmentObject(HealthKitManager())
        .environmentObject(WeatherManager())
}
