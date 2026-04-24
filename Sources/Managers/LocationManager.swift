import CoreLocation
import Combine
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let clManager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var waypoints: [CLLocation] = []
    @Published var isTracking = false
    @Published var isPaused = false

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = 5      // record every 5 m of movement
        clManager.activityType = .fitness
        clManager.allowsBackgroundLocationUpdates = false
    }

    func requestPermission() {
        clManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        waypoints = []
        isTracking = true
        isPaused = false
        clManager.startUpdatingLocation()
    }

    func pauseTracking() {
        isPaused = true
        clManager.stopUpdatingLocation()
    }

    func resumeTracking() {
        isPaused = false
        clManager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        clManager.stopUpdatingLocation()
    }

    // Called after the user reviews the summary — wipes everything from RAM
    func clearSession() {
        waypoints = []
        currentLocation = nil
        isTracking = false
        isPaused = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              loc.horizontalAccuracy >= 0,
              loc.horizontalAccuracy <= 50 else { return }
        currentLocation = loc
        if isTracking && !isPaused {
            waypoints.append(loc)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
