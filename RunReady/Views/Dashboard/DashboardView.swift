import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(UserPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var isShowingAddRun = false
    @State private var isShowingActiveRun = false

    var body: some View {
        NavigationStack {
            ZStack {
                RunReadyGradient()

                ScrollView {
                    VStack(spacing: 20) {
                        // Greeting
                        greetingHeader

                        // Stats grid
                        StatCardGrid(
                            today: viewModel.todayDistance,
                            week: viewModel.weekDistance,
                            month: viewModel.monthDistance,
                            year: viewModel.yearDistance
                        )
                        .padding(.horizontal)

                        // Readiness banner
                        readinessBanner
                            .padding(.horizontal)

                        // Quick actions
                        quickActions
                            .padding(.horizontal)

                        // Latest run
                        if let latest = viewModel.latestRun {
                            latestRunCard(latest)
                                .padding(.horizontal)
                        }

                        // HealthKit sync
                        if appState.healthKitManager.isAvailable {
                            syncButton
                                .padding(.horizontal)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("RunReady")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isShowingAddRun) {
                AddRunView()
            }
            .fullScreenCover(isPresented: $isShowingActiveRun) {
                ActiveRunView()
            }
            .onAppear {
                viewModel.load(from: modelContext)
            }
        }
    }

    // MARK: - Subviews

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if viewModel.streak > 0 {
                    Label("\(viewModel.streak)-day streak 🔥", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Text(viewModel.totalRuns > 0 ? "\(viewModel.totalRuns) runs" : "No runs yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var readinessBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Race Readiness", systemImage: "checkmark.seal.fill")

            if let recommended = viewModel.readinessAssessment.recommendedDistance {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Text(recommended.emoji)
                            .font(.title2)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Safe to race: \(recommended.shortLabel)")
                            .font(.headline)
                        if let next = viewModel.readinessAssessment.nextTargetDistance,
                           let nextScore = viewModel.readinessAssessment.scores[next] {
                            Text("Working toward \(next.shortLabel) — \(String(format: "%.0f%%", nextScore.score)) ready")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1))
            } else {
                Label("Log more runs to get a recommendation", systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                isShowingActiveRun = true
            } label: {
                Label("Start Run", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button {
                isShowingAddRun = true
            } label: {
                Label("Log Run", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func latestRunCard(_ run: RunWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Latest Run", systemImage: "clock")
            RunRow(run: run)
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var syncButton: some View {
        Button {
            Task { await viewModel.syncHealthKit(modelContext: modelContext) }
        } label: {
            HStack {
                if viewModel.isLoadingHealthKit {
                    ProgressView().tint(.white)
                        .scaleEffect(0.8)
                }
                Label("Sync Apple Health", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.red.opacity(0.12))
            .foregroundStyle(.red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isLoadingHealthKit)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default:      return "Good evening 👋"
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
