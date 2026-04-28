import SwiftUI
import MapKit
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    let waypoints: [CLLocation]
    let currentLocation: CLLocation?
    @Binding var isFollowing: Bool

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.mapType = .mutedStandard
        map.showsUserLocation = true
        map.showsBuildings = true
        map.showsCompass = false   // hide the default top-right compass
        map.isPitchEnabled = true
        map.pointOfInterestFilter = .includingAll
        map.userTrackingMode = .followWithHeading

        // Custom compass pinned to the bottom-right, above the control panel
        let compass = MKCompassButton(mapView: map)
        compass.compassVisibility = .adaptive
        compass.translatesAutoresizingMaskIntoConstraints = false
        map.addSubview(compass)
        NSLayoutConstraint.activate([
            compass.trailingAnchor.constraint(equalTo: map.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            compass.bottomAnchor.constraint(equalTo: map.bottomAnchor, constant: -220)
        ])

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
        private var centeredOnce = false

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !centeredOnce, let loc = userLocation.location else { return }
            centeredOnce = true
            // Apply 3D camera on first real location fix
            let cam = MKMapCamera(
                lookingAtCenter: loc.coordinate,
                fromDistance: 400,
                pitch: 45,
                heading: mapView.camera.heading
            )
            mapView.setCamera(cam, animated: true)
            mapView.setUserTrackingMode(.followWithHeading, animated: false)
        }

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
