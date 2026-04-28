import SwiftUI
import MapKit

/// Static, non-interactive map used in the post-hike summary.
struct RouteMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isUserInteractionEnabled = false
        map.mapType = .mutedStandard
        map.isPitchEnabled = false
        map.showsBuildings = true
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .includingAll
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations)
        map.removeOverlays(map.overlays)
        guard !coordinates.isEmpty else { return }

        if coordinates.count > 1 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            map.addOverlay(polyline)
            map.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 48, left: 32, bottom: 48, right: 32),
                animated: false
            )
            // Tilt the summary overview to 3D after the region is set
            let cam = MKMapCamera(
                lookingAtCenter: map.region.center,
                fromDistance: map.camera.altitude,
                pitch: 45,
                heading: map.camera.heading
            )
            map.setCamera(cam, animated: false)
        } else if let only = coordinates.first {
            map.setCenter(only, animated: false)
        }

        addPin(to: map, coordinate: coordinates.first!, title: "Start", isStart: true)
        if coordinates.count > 1 {
            addPin(to: map, coordinate: coordinates.last!, title: "Finish", isStart: false)
        }
    }

    private func addPin(to map: MKMapView, coordinate: CLLocationCoordinate2D, title: String, isStart: Bool) {
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title = title
        map.addAnnotation(pin)
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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            let isStart = annotation.title == "Start"
            view.markerTintColor = isStart ? .systemGreen : .systemRed
            view.glyphImage = UIImage(systemName: isStart ? "flag.fill" : "flag.checkered")
            view.displayPriority = .required
            return view
        }
    }
}
