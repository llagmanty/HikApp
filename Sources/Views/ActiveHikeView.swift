import SwiftUI
import MapKit
import CoreLocation

struct ActiveHikeView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Date()
    @State private var elapsed: TimeInterval = 0
    @State private var ticker: Timer?
    @State private var isFollowing = true

    @State private var completedSession: HikingSession?
    @State private var showingSummary = false
    @State private var sessionFinished = false

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
        .onAppear(perform: beginSession)
        .onDisappear(perform: stopTicker)
        .fullScreenCover(isPresented: $showingSummary, onDismiss: {
            if sessionFinished { dismiss() }
        }) {
            if let s = completedSession {
                SummaryView(session: s) {
                    locationManager.clearSession()
                }
            }
        }
    }

    // MARK: - Status banner

    private var statusBanner: some View {
        HStack {
            Circle()
                .fill(locationManager.isPaused ? Color.orange : Color.green)
                .frame(width: 10, height: 10)
                .shadow(color: locationManager.isPaused ? .orange : .green, radius: 4)

            Text(locationManager.isPaused ? "Paused" : "Recording")
                .font(.caption.bold())
                .foregroundStyle(.white)

            Spacer()

            Text(elapsed.formattedDuration)
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.55).shadow(.drop(radius: 4)))
        .padding(.top, 1)  // sits just below the status bar
    }

    // MARK: - Control panel

    private var controlPanel: some View {
        VStack(spacing: 14) {
            statsRow
            buttonRow
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(radius: 12, y: -2)
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
        locationManager.startTracking()
        startTicker()
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

        var s = HikingSession(startTime: startTime, endTime: Date())
        s.waypoints = locationManager.waypoints
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
