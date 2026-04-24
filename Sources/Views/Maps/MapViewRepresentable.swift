import SwiftUI
import MapKit
import CoreLocation

/// Live map shown during an active hike — follows user position and draws the route polyline.
struct MapViewRepresentable: UIViewRepresentable {
    let waypoints: [CLLocation]
    let currentLocation: CLLocation?
    @Binding var isFollowing: Bool

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.showsCompass = true
        map.pointOfInterestFilter = .includingAll
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        guard waypoints.count > 1 else { return }
        let coords = waypoints.map(\.coordinate)
        map.addOverlay(MKPolyline(coordinates: coords, count: coords.count))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = .systemGreen
            r.lineWidth = 5
            r.lineCap = .round
            r.lineJoin = .round
            return r
        }
    }
}
