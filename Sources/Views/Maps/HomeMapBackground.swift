import SwiftUI
import MapKit
import CoreLocation

/// Non-interactive map used as the HomeView background.
/// Centers on the user's location with a 3D tilt when available.
struct HomeMapBackground: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.mapType = .mutedStandard
        map.showsUserLocation = true
        map.isUserInteractionEnabled = false
        map.showsBuildings = true
        map.showsCompass = false
        map.showsScale = false
        map.pointOfInterestFilter = .includingAll
        map.setCamera(camera(for: coordinate), animated: false)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard let coord = coordinate else { return }
        map.setCamera(camera(for: coord), animated: true)
    }

    private func camera(for coord: CLLocationCoordinate2D?) -> MKMapCamera {
        MKMapCamera(
            lookingAtCenter: coord ?? CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312),
            fromDistance: 1400,
            pitch: 50,
            heading: 15
        )
    }
}
