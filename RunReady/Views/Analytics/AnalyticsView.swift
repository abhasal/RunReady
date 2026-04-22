import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(UserPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                RunReadyGradient()

                ScrollView {
                    VStack(spacing: 20) {
                        lifetimeStats
                            .padding(.horizontal)

                        weeklyChart
                            .padding(.horizontal)

                        monthlyBreakdown
                            .padding(.horizontal)

                        personalRecordCard
                            .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Analytics")
            .onAppear { viewModel.load(modelContext: modelContext) }
        }
    }

    // MARK: - Sections

    private var lifetimeStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("All Time", systemImage: "trophy")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Total Runs",
                    value: "\(viewModel.totalLifetimeRuns)",
                    icon: "figure.run",
                    accentColor: .blue
                )
                StatCard(
                    title: "Total Distance",
                    value: UnitConversionService.formattedDistanceCompact(
                        viewModel.totalLifetimeMeters, unit: prefs.unitSystem),
                    icon: "map",
                    accentColor: .purple
                )
                StatCard(
                    title: "Best Streak",
                    value: "\(viewModel.longestStreak) days",
                    icon: "flame.fill",
                    accentColor: .orange
                )
                if let pr = viewModel.personalRecord {
                    StatCard(
                        title: "Longest Run",
                        value: UnitConversionService.formattedDistanceCompact(
                            pr.distanceMeters, unit: prefs.unitSystem),
                        icon: "medal",
                        accentColor: .yellow
                    )
                }
            }
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Weekly Volume (12 weeks)", systemImage: "chart.bar.fill")

            if viewModel.weeklyData.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Chart(viewModel.weeklyData) { point in
                    BarMark(
                        x: .value("Week", point.label),
                        y: .value("Distance", UnitConversionService.metersToPreferred(point.totalMeters, unit: prefs.unitSystem))
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text(String(format: "%.0f", d))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var monthlyBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Monthly Summary (6 months)", systemImage: "calendar")

            VStack(spacing: 8) {
                ForEach(viewModel.monthlyStats.reversed()) { stat in
                    HStack {
                        Text(stat.label)
                            .font(.subheadline.bold())
                            .frame(width: 80, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(UnitConversionService.formattedDistanceCompact(stat.totalMeters, unit: prefs.unitSystem))
                                .font(.subheadline)
                            Text("\(stat.runCount) run(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let pace = stat.avgPaceSecondsPerMeter {
                            Text(UnitConversionService.formattedPace(secondsPerMeter: pace, unit: prefs.unitSystem))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var personalRecordCard: some View {
        Group {
            if let pr = viewModel.personalRecord {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("Personal Record", systemImage: "medal.fill")
                    HStack(spacing: 16) {
                        Text("🏅")
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(UnitConversionService.formattedDistanceCompact(pr.distanceMeters, unit: prefs.unitSystem))
                                .font(.title2.bold())
                            Text(formatDate(pr.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let pace = pr.averagePaceSecondsPerMeter {
                                Text("@ " + UnitConversionService.formattedPace(secondsPerMeter: pace, unit: prefs.unitSystem))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: date)
    }
}

#Preview {
    AnalyticsView()
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
