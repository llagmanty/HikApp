import Testing
import CoreLocation
@testable import HikApp

@Suite("HikingSession")
struct HikingSessionTests {

    private func makeLoc(lat: Double = 0, lon: Double = 0, alt: Double = 0, speed: Double = -1) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: alt,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: -1,
            speed: speed,
            timestamp: Date()
        )
    }

    @Test func emptySessionDefaults() {
        let s = HikingSession(startTime: Date())
        #expect(s.totalDistance == 0)
        #expect(s.elevationGain == 0)
        #expect(s.elevationLoss == 0)
        #expect(s.maxAltitude == 0)
        #expect(s.minAltitude == 0)
        #expect(s.maxSpeed == 0)
        #expect(s.averageSpeed == 0)
        #expect(s.coordinates.isEmpty)
    }

    @Test func singleWaypointReturnsZeros() {
        var s = HikingSession(startTime: Date())
        s.waypoints = [makeLoc()]
        #expect(s.totalDistance == 0)
        #expect(s.elevationGain == 0)
        #expect(s.elevationLoss == 0)
    }

    @Test func totalDistanceAccumulatesCorrectly() {
        var s = HikingSession(startTime: Date())
        let a = makeLoc(lat: 0, lon: 0)
        let b = makeLoc(lat: 0, lon: 0.001)
        let c = makeLoc(lat: 0, lon: 0.002)
        s.waypoints = [a, b, c]

        let expected = a.distance(from: b) + b.distance(from: c)
        #expect(abs(s.totalDistance - expected) < 0.01)
    }

    @Test func elevationGainIgnoresDescents() {
        var s = HikingSession(startTime: Date())
        s.waypoints = [
            makeLoc(alt: 100),
            makeLoc(alt: 150),
            makeLoc(alt: 130),
            makeLoc(alt: 200)
        ]
        // gain: 50 + 0 + 70 = 120
        #expect(s.elevationGain == 120)
    }

    @Test func elevationLossIgnoresAscents() {
        var s = HikingSession(startTime: Date())
        s.waypoints = [
            makeLoc(alt: 200),
            makeLoc(alt: 150),
            makeLoc(alt: 180),
            makeLoc(alt: 100)
        ]
        // loss: 50 + 0 + 80 = 130
        #expect(s.elevationLoss == 130)
    }

    @Test func minMaxAltitude() {
        var s = HikingSession(startTime: Date())
        s.waypoints = [makeLoc(alt: 10), makeLoc(alt: 50), makeLoc(alt: 30)]
        #expect(s.maxAltitude == 50)
        #expect(s.minAltitude == 10)
    }

    @Test func maxSpeedIgnoresNegativeValues() {
        var s = HikingSession(startTime: Date())
        s.waypoints = [makeLoc(speed: -1), makeLoc(speed: 3.5), makeLoc(speed: 2.0)]
        #expect(s.maxSpeed == 3.5)
    }

    @Test func averageSpeedIsDistanceOverDuration() {
        let start = Date()
        var s = HikingSession(startTime: start, endTime: start.addingTimeInterval(100))
        let a = makeLoc(lat: 0, lon: 0)
        let b = makeLoc(lat: 0, lon: 0.001)
        s.waypoints = [a, b]

        let expected = s.totalDistance / 100
        #expect(abs(s.averageSpeed - expected) < 0.01)
    }

    @Test func coordinatesMatchWaypoints() {
        var s = HikingSession(startTime: Date())
        s.waypoints = [makeLoc(lat: 1, lon: 2), makeLoc(lat: 3, lon: 4)]
        #expect(s.coordinates.count == 2)
        #expect(s.coordinates[0].latitude == 1)
        #expect(s.coordinates[1].longitude == 4)
    }
}
