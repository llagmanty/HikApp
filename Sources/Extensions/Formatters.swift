import Foundation
import CoreLocation

extension TimeInterval {
    var formattedDuration: String {
        let h = Int(self) / 3600
        let m = (Int(self) % 3600) / 60
        let s = Int(self) % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}

extension CLLocationDistance {
    var formattedDistance: String {
        self >= 1000
            ? String(format: "%.2f km", self / 1000)
            : String(format: "%.0f m", self)
    }
}

extension Double {
    /// Converts m/s to a km/h display string.
    var formattedSpeed: String {
        String(format: "%.1f km/h", self * 3.6)
    }
}
