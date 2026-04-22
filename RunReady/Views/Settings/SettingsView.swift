import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(UserPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                RunReadyGradient()

                List {
                    // Units
                    Section("Measurement") {
                        Picker("Unit System", selection: Bindable(prefs).unitSystem) {
                            ForEach(UnitSystem.allCases, id: \.self) { system in
                                Text(system.rawValue).tag(system)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                    }

                    // HealthKit
                    Section("Apple Health") {
                        if appState.healthKitManager.isAvailable {
                            Button {
                                Task { await viewModel.syncHealthKit(modelContext: modelContext) }
                            } label: {
                                HStack {
                                    Label("Sync Workouts", systemImage: "arrow.triangle.2.circlepath")
                                    Spacer()
                                    if viewModel.isSyncing {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(viewModel.isSyncing)
                        } else {
                            Label("HealthKit unavailable on this device", systemImage: "heart.slash")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Preferences
                    Section("Display") {
                        Toggle(isOn: Bindable(prefs).showHeartRate) {
                            Label("Show Heart Rate", systemImage: "heart")
                        }
                    }

                    // Reminders
                    Section("Notifications") {
                        Toggle(isOn: Bindable(prefs).enableRunReminders) {
                            Label("Run Reminders", systemImage: "bell")
                        }
                        // TODO: Schedule UNUserNotificationCenter when this is enabled
                    }

                    // About
                    Section("About") {
                        LabeledContent("Version", value: appVersion)
                        Link(destination: URL(string: "https://example.com/privacy")!) {
                            Label("Privacy Policy", systemImage: "lock.shield")
                        }
                        // TODO: Replace with real privacy policy URL before App Store submission
                    }

                    // Danger zone
                    Section("Data") {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete All Runs", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Delete All Runs?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    try? viewModel.deleteAllRuns(modelContext: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your run data. This cannot be undone.")
            }
            .overlay(alignment: .bottom) {
                if let msg = viewModel.syncMessage {
                    Text(msg)
                        .font(.caption)
                        .padding(10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.syncMessage = nil
                            }
                        }
                }
            }
            .animation(.easeInOut, value: viewModel.syncMessage)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
