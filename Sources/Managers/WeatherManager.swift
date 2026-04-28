import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherManager: ObservableObject {
    @Published var temperature: Measurement<UnitTemperature>?
    @Published var symbolName: String = "cloud"
    @Published var isFetching = false

    private let service = WeatherService.shared
    private var lastFetchDate: Date?
    private var lastFetchLocation: CLLocation?

    func fetchIfNeeded(for location: CLLocation) async {
        if let lastDate = lastFetchDate,
           let lastLoc = lastFetchLocation,
           Date().timeIntervalSince(lastDate) < 900,
           lastLoc.distance(from: location) < 10_000 {
            return
        }
        await fetch(for: location)
    }

    private func fetch(for location: CLLocation) async {
        isFetching = true
        defer { isFetching = false }
        do {
            let weather = try await service.weather(for: location)
            temperature = weather.currentWeather.temperature
            symbolName = weather.currentWeather.symbolName
            lastFetchDate = Date()
            lastFetchLocation = location
        } catch {
            // weather is non-critical
        }
    }
}

extension Measurement where UnitType == UnitTemperature {
    var localizedString: String {
        let unit: UnitTemperature = Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
        let fmt = MeasurementFormatter()
        fmt.unitOptions = .providedUnit
        fmt.numberFormatter.maximumFractionDigits = 0
        return fmt.string(from: converted(to: unit))
    }
}
