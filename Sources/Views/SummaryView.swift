import SwiftUI
import MapKit

struct SummaryView: View {
    let session: HikingSession
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    routeMap
                    statsGrid
                    privacyFooter
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Hike Summary")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .confirmationDialog(
            "Delete this hike session?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete & Finish", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Keep reviewing", role: .cancel) {}
        } message: {
            Text("All route data will be permanently removed from memory. This cannot be undone.")
        }
    }

    // MARK: - Route map

    private var routeMap: some View {
        RouteMapView(coordinates: session.coordinates)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal)
            .padding(.top, 4)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stats")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                SummaryStatCard(
                    label: "Distance",
                    value: session.totalDistance.formattedDistance,
                    icon: "map.fill",
                    color: .blue
                )
                SummaryStatCard(
                    label: "Duration",
                    value: session.duration.formattedDuration,
                    icon: "clock.fill",
                    color: .purple
                )
                SummaryStatCard(
                    label: "Elev. Gain",
                    value: String(format: "%.0f m", session.elevationGain),
                    icon: "arrow.up.right",
                    color: .green
                )
                SummaryStatCard(
                    label: "Elev. Loss",
                    value: String(format: "%.0f m", session.elevationLoss),
                    icon: "arrow.down.right",
                    color: .orange
                )
                SummaryStatCard(
                    label: "Max Speed",
                    value: session.maxSpeed.formattedSpeed,
                    icon: "speedometer",
                    color: .red
                )
                SummaryStatCard(
                    label: "Avg Speed",
                    value: session.averageSpeed.formattedSpeed,
                    icon: "figure.walk",
                    color: .teal
                )
                SummaryStatCard(
                    label: "Max Altitude",
                    value: String(format: "%.0f m", session.maxAltitude),
                    icon: "mountain.2.fill",
                    color: .indigo
                )
                SummaryStatCard(
                    label: "Waypoints",
                    value: "\(session.waypoints.count)",
                    icon: "mappin.circle.fill",
                    color: .pink
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Privacy footer

    private var privacyFooter: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("Zero data retained")
                    .font(.headline)
                Text("Your route and stats exist only in memory right now. Tapping the button below erases them permanently — no backup, no cloud, no trace.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Button {
                showDeleteConfirm = true
            } label: {
                Label("Finish & Delete Data", systemImage: "trash.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}
