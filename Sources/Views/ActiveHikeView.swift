import SwiftUI
import MapKit
import CoreLocation
import CoreMotion

struct ActiveHikeView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var weatherManager: WeatherManager
    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Date()
    @State private var elapsed: TimeInterval = 0
    @State private var ticker: Timer?
    @State private var isFollowing = true
    @State private var stepCount: Int = 0

    @State private var completedSession: HikingSession?
    @State private var showingSummary = false
    @State private var sessionFinished = false

    private let pedometer = CMPedometer()

    var body: some View {
        ZStack(alignment: .bottom) {
            MapViewRepresentable(
                waypoints: locationManager.waypoints,
                currentLocation: locationManager.currentLocation,
                isFollowing: $isFollowing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                statusBanner
                Spacer()
                controlPanel
            }
        }
        .overlay(alignment: .topLeading) {
            if weatherManager.temperature != nil || weatherManager.isFetching {
                WeatherWidget(
                    temperature: weatherManager.temperature,
                    symbolName: weatherManager.symbolName,
                    isFetching: weatherManager.isFetching
                )
                .padding(.leading, 16)
                .padding(.top, 110)
            }
        }
        .task(id: locationManager.currentLocation) {
            guard let loc = locationManager.currentLocation else { return }
            await weatherManager.fetchIfNeeded(for: loc)
        }
        .onAppear(perform: beginSession)
        .onDisappear(perform: stopTicker)
        .fullScreenCover(isPresented: $showingSummary, onDismiss: {
            if sessionFinished { dismiss() }
        }) {
            if let s = completedSession {
                SummaryView(session: s) {
                    locationManager.clearSession()
                    healthKitManager.reset()
                }
            }
        }
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack(spacing: 16) {

            // Left: timer
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(elapsed.formattedDuration)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)

                    // Accent bar
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.20, blue: 0.95),
                                 Color(red: 0.25, green: 0.45, blue: 1.00)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 80, height: 3)
                    .clipShape(Capsule())
                }
            }

            Spacer()

            // Center: heart rate
            if let hr = healthKitManager.currentHeartRate {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("\(Int(hr))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    }
                    Text("BPM")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Right: step count
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(stepCount)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text("Steps")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Control panel

    private var controlPanel: some View {
        VStack(spacing: 14) {
            statsRow
            buttonRow
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 24)
    }

    private var statsRow: some View {
        let pts = locationManager.waypoints
        let dist = distance(from: pts)
        let gain = elevationGain(from: pts)
        let speed = max(0, locationManager.currentLocation?.speed ?? 0)

        return HStack(spacing: 10) {
            StatTile(label: "Distance", value: dist.formattedDistance, icon: "map")
            StatTile(label: "Elev. Gain", value: String(format: "%.0f m", gain), icon: "arrow.up.right")
            StatTile(label: "Speed", value: speed.formattedSpeed, icon: "speedometer")
            if healthKitManager.activeCalories > 0 {
                StatTile(label: "Calories", value: String(format: "%.0f", healthKitManager.activeCalories), icon: "flame.fill")
            }
            if let temp = weatherManager.temperature {
                StatTile(label: "Temp", value: temp.localizedString, icon: weatherManager.symbolName)
            }
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button(action: togglePause) {
                Label(
                    locationManager.isPaused ? "Resume" : "Pause",
                    systemImage: locationManager.isPaused ? "play.fill" : "pause.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(locationManager.isPaused ? Color.green : Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            }

            Button(action: finishSession) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
        }
    }

    // MARK: - Session lifecycle

    private func beginSession() {
        startTime = Date()
        elapsed = 0
        stepCount = 0
        locationManager.startTracking()
        startTicker()
        startPedometer()
        Task {
            let authorized = await healthKitManager.requestAuthorization()
            if authorized {
                healthKitManager.startObserving(from: startTime)
            }
        }
    }

    private func togglePause() {
        if locationManager.isPaused {
            locationManager.resumeTracking()
            startTicker()
        } else {
            locationManager.pauseTracking()
            stopTicker()
        }
    }

    private func finishSession() {
        locationManager.stopTracking()
        stopTicker()
        pedometer.stopUpdates()
        healthKitManager.stopObserving()

        var s = HikingSession(startTime: startTime, endTime: Date())
        s.waypoints = locationManager.waypoints
        s.heartRateSamples = healthKitManager.heartRateSamples
        s.activeCalories = healthKitManager.activeCalories
        completedSession = s
        sessionFinished = true
        showingSummary = true
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: startTime) { data, error in
            guard let data, error == nil else { return }
            DispatchQueue.main.async {
                stepCount = data.numberOfSteps.intValue
            }
        }
    }

    // MARK: - Stat helpers

    private func distance(from pts: [CLLocation]) -> CLLocationDistance {
        guard pts.count > 1 else { return 0 }
        return zip(pts, pts.dropFirst()).reduce(0) { $0 + $1.1.distance(from: $1.0) }
    }

    private func elevationGain(from pts: [CLLocation]) -> Double {
        guard pts.count > 1 else { return 0 }
        return zip(pts, pts.dropFirst()).reduce(0) {
            let d = $1.1.altitude - $1.0.altitude
            return $0 + (d > 0 ? d : 0)
        }
    }
}
