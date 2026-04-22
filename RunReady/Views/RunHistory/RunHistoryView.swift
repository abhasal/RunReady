import SwiftUI
import SwiftData

struct RunHistoryView: View {
    @Environment(UserPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunWorkout.date, order: .reverse) private var runs: [RunWorkout]
    @State private var isShowingAddRun = false
    @State private var searchText = ""
    @State private var selectedFilter: SourceFilter = .all

    enum SourceFilter: String, CaseIterable {
        case all      = "All"
        case tracked  = "Tracked"
        case manual   = "Manual"
        case health   = "Health"
    }

    private var filteredRuns: [RunWorkout] {
        var result = runs
        if !searchText.isEmpty {
            result = result.filter { run in
                (run.notes ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        switch selectedFilter {
        case .all:     break
        case .tracked: result = result.filter { $0.sourceType == .liveTracked }
        case .manual:  result = result.filter { $0.sourceType == .manual }
        case .health:  result = result.filter { $0.sourceType == .healthKit }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunReadyGradient()

                Group {
                    if runs.isEmpty {
                        emptyState
                    } else {
                        runList
                    }
                }
            }
            .navigationTitle("Run History")
            .searchable(text: $searchText, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddRun = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddRun) {
                AddRunView()
            }
        }
    }

    private var runList: some View {
        List {
            // Filter pills
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SourceFilter.allCases, id: \.self) { filter in
                            Button(filter.rawValue) {
                                selectedFilter = filter
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == filter ? Color.blue : Color.secondary.opacity(0.15))
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("\(filteredRuns.count) runs") {
                ForEach(filteredRuns) { run in
                    NavigationLink {
                        RunDetailView(run: run)
                    } label: {
                        RunRow(run: run)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteRun(run)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Runs Yet")
                .font(.title2.bold())
            Text("Start tracking or import from Apple Health to see your runs here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                isShowingAddRun = true
            } label: {
                Label("Add a Run", systemImage: "plus")
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func deleteRun(_ run: RunWorkout) {
        modelContext.delete(run)
        try? modelContext.save()
    }
}

#Preview {
    RunHistoryView()
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
