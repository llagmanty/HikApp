import Testing
import CoreLocation
@testable import HikApp

@Suite("Formatters")
struct FormattersTests {

    // MARK: - TimeInterval.formattedDuration

    @Test func durationUnderOneHour() {
        let value: TimeInterval = 754  // 12m 34s
        #expect(value.formattedDuration == "12:34")
    }

    @Test func durationOverOneHour() {
        let value: TimeInterval = 3661  // 1h 1m 1s
        #expect(value.formattedDuration == "1:01:01")
    }

    @Test func durationZero() {
        let value: TimeInterval = 0
        #expect(value.formattedDuration == "00:00")
    }

    // MARK: - CLLocationDistance.formattedDistance

    @Test func distanceInMeters() {
        let value: CLLocationDistance = 750
        #expect(value.formattedDistance == "750 m")
    }

    @Test func distanceInKilometers() {
        let value: CLLocationDistance = 2345
        #expect(value.formattedDistance == "2.35 km")
    }

    @Test func distanceExactlyOneKm() {
        let value: CLLocationDistance = 1000
        #expect(value.formattedDistance == "1.00 km")
    }

    // MARK: - Double.formattedSpeed

    @Test func speedConversion() {
        let mps: Double = 1.0  // 1 m/s = 3.6 km/h
        #expect(mps.formattedSpeed == "3.6 km/h")
    }

    @Test func speedZero() {
        let mps: Double = 0.0
        #expect(mps.formattedSpeed == "0.0 km/h")
    }
}
