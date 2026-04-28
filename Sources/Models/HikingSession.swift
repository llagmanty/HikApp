import CoreLocation
import Foundation

struct HikingSession {
    let startTime: Date
    var endTime: Date?
    var waypoints: [CLLocation] = []

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var totalDistance: CLLocationDistance {
        guard waypoints.count > 1 else { return 0 }
        return zip(waypoints, waypoints.dropFirst())
            .reduce(0) { $0 + $1.1.distance(from: $1.0) }
    }

    var elevationGain: Double {
        guard waypoints.count > 1 else { return 0 }
        return zip(waypoints, waypoints.dropFirst()).reduce(0) {
            let d = $1.1.altitude - $1.0.altitude
            return $0 + (d > 0 ? d : 0)
        }
    }

    var elevationLoss: Double {
        guard waypoints.count > 1 else { return 0 }
        return zip(waypoints, waypoints.dropFirst()).reduce(0) {
            let d = $1.0.altitude - $1.1.altitude
            return $0 + (d > 0 ? d : 0)
        }
    }

    var maxAltitude: Double { waypoints.map(\.altitude).max() ?? 0 }
    var minAltitude: Double { waypoints.map(\.altitude).min() ?? 0 }

    var maxSpeed: Double {
        waypoints.compactMap { $0.speed > 0 ? $0.speed : nil }.max() ?? 0
    }

    var averageSpeed: Double {
        duration > 0 ? totalDistance / duration : 0
    }

    var coordinates: [CLLocationCoordinate2D] {
        waypoints.map(\.coordinate)
    }

    // MARK: - Health data (from Apple Watch via HealthKit)

    var heartRateSamples: [(date: Date, bpm: Double)] = []
    var activeCalories: Double = 0

    var averageHeartRate: Double? {
        guard !heartRateSamples.isEmpty else { return nil }
        return heartRateSamples.map(\.bpm).reduce(0, +) / Double(heartRateSamples.count)
    }

    var maxHeartRate: Double? {
        heartRateSamples.map(\.bpm).max()
    }

    var minHeartRate: Double? {
        heartRateSamples.map(\.bpm).min()
    }
}
