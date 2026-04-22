import SwiftUI
import SwiftData

struct ReadinessView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReadinessViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                RunReadyGradient()

                if viewModel.isLoading {
                    ProgressView("Analyzing training…")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            disclaimerBanner
                                .padding(.horizontal)

                            recommendationHero
                                .padding(.horizontal)

                            distanceCards
                                .padding(.horizontal)

                            algorithmExplainer
                                .padding(.horizontal)

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Race Readiness")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.refresh(modelContext: modelContext)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.refresh(modelContext: modelContext)
            }
        }
    }

    // MARK: - Subviews

    private var disclaimerBanner: some View {
        Label(
            "This is training guidance, not medical advice. Consult a healthcare professional before racing.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(12)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var recommendationHero: some View {
        VStack(spacing: 14) {
            if let recommended = viewModel.assessment.recommendedDistance {
                VStack(spacing: 8) {
                    Text("You're safely ready for")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(recommended.emoji + " " + recommended.shortLabel)
                        .font(.largeTitle.bold())
                    if let next = viewModel.assessment.nextTargetDistance,
                       let nextScore = viewModel.assessment.scores[next] {
                        VStack(spacing: 4) {
                            Text("Working toward \(next.shortLabel)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            ProgressView(value: nextScore.progressFraction)
                                .tint(.blue)
                                .frame(width: 200)
                            Text(String(format: "%.0f%% there", nextScore.score))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.green.opacity(0.3), lineWidth: 1))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Not enough training data yet")
                        .font(.headline)
                    Text("Log consistent runs for at least 2–4 weeks and we'll assess your race readiness.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var distanceCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("All Distances", systemImage: "list.bullet.indent")

            ForEach(viewModel.assessment.orderedScores) { score in
                NavigationLink {
                    ReadinessDetailView(score: score)
                } label: {
                    ReadinessCard(score: score)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var algorithmExplainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("How It's Calculated", systemImage: "function")

            VStack(alignment: .leading, spacing: 8) {
                explainerRow(icon: "arrow.up.right", color: .blue,
                             title: "Long Run (35%)", detail: "Longest run in the last 4 weeks")
                explainerRow(icon: "chart.bar", color: .purple,
                             title: "Weekly Volume (30%)", detail: "Avg weekly distance over 4 weeks")
                explainerRow(icon: "calendar", color: .orange,
                             title: "Frequency (20%)", detail: "Avg runs per week over 8 weeks")
                explainerRow(icon: "checkmark.circle", color: .green,
                             title: "Consistency (15%)", detail: "Active weeks in last 12 weeks")
                explainerRow(icon: "exclamationmark.triangle", color: .red,
                             title: "Safety Cap", detail: "Score capped if weekly jump >40%")
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func explainerRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Detail view for a single distance

struct ReadinessDetailView: View {
    let score: RaceReadinessScore

    var body: some View {
        ZStack {
            RunReadyGradient()
            ScrollView {
                VStack(spacing: 16) {
                    ReadinessCardExpanded(score: score)
                        .padding(.horizontal)
                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle(score.distance.shortLabel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ReadinessView()
        .modelContainer(PreviewData.container)
}
