import SwiftUI

@main
struct HikApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var weatherManager = WeatherManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(healthKitManager)
                .environmentObject(weatherManager)
        }
    }
}
