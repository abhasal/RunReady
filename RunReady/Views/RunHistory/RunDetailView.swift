import SwiftUI
import MapKit

struct RunDetailView: View {
    let run: RunWorkout
    @Environment(UserPreferences.self) private var prefs
    @State private var isEditingNotes = false
    @State private var notesText: String = ""

    var body: some View {
        ZStack {
            RunReadyGradient()

            ScrollView {
                VStack(spacing: 20) {
                    // Map or placeholder
                    if run.hasRoute {
                        RouteMapView(routePoints: run.routePoints)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }

                    // Core stats
                    coreStatsGrid
                        .padding(.horizontal)

                    // Additional metrics
                    additionalMetrics
                        .padding(.horizontal)

                    // Notes
                    notesSection
                        .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle(dateTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { notesText = run.notes ?? "" }
    }

    // MARK: - Subviews

    private var coreStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Distance",
                value: UnitConversionService.formattedDistanceCompact(run.distanceMeters, unit: prefs.unitSystem),
                icon: "arrow.right.circle",
                accentColor: .blue
            )
            StatCard(
                title: "Duration",
                value: UnitConversionService.formattedDuration(run.duration),
                icon: "timer",
                accentColor: .orange
            )
            if let pace = run.averagePaceSecondsPerMeter {
                StatCard(
                    title: "Avg Pace",
                    value: UnitConversionService.formattedPace(secondsPerMeter: pace, unit: prefs.unitSystem),
                    icon: "speedometer",
                    accentColor: .purple
                )
            }
            if let cal = run.calories {
                StatCard(
                    title: "Calories",
                    value: UnitConversionService.formattedCalories(cal),
                    icon: "flame",
                    accentColor: .red
                )
            }
        }
    }

    private var additionalMetrics: some View {
        Group {
            if let hr = run.heartRateAvgBPM {
                LabeledContent("Avg Heart Rate") {
                    Label(String(format: "%.0f bpm", hr), systemImage: "heart.fill")
                        .foregroundStyle(.red)
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Notes", systemImage: "note.text",
                          actionLabel: "Edit") {
                isEditingNotes = true
            }

            Text(run.notes?.isEmpty == false ? run.notes! : "No notes for this run.")
                .font(.body)
                .foregroundStyle(run.notes?.isEmpty == false ? .primary : .secondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .sheet(isPresented: $isEditingNotes) {
            NotesEditSheet(text: $notesText, run: run)
        }
    }

    private var dateTitle: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: run.date)
    }
}

// MARK: - Route map

struct RouteMapView: View {
    let routePoints: [RoutePoint]

    private var region: MKCoordinateRegion {
        guard !routePoints.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.334, longitude: -122.009),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        let lats = routePoints.map(\.latitude)
        let lngs = routePoints.map(\.longitude)
        let centerLat = (lats.min()! + lats.max()!) / 2
        let centerLng = (lngs.min()! + lngs.max()!) / 2
        let spanLat = (lats.max()! - lats.min()!) * 1.4
        let spanLng = (lngs.max()! - lngs.min()!) * 1.4
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.005), longitudeDelta: max(spanLng, 0.005))
        )
    }

    var body: some View {
        Map(initialPosition: .region(region)) {
            if routePoints.count > 1 {
                MapPolyline(coordinates: routePoints.map(\.coordinate))
                    .stroke(.blue, lineWidth: 3)
            }
            if let first = routePoints.first {
                Annotation("Start", coordinate: first.coordinate) {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            if let last = routePoints.last, routePoints.count > 1 {
                Annotation("End", coordinate: last.coordinate) {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .disabled(true)
    }
}

// MARK: - Notes edit sheet

struct NotesEditSheet: View {
    @Binding var text: String
    let run: RunWorkout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding()
                .navigationTitle("Edit Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            run.notes = text
                            dismiss()
                        }
                    }
                }
        }
    }
}
