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

                    // Legal
                    Section("Legal") {
                        NavigationLink {
                            DisclaimerView()
                        } label: {
                            Label("Disclaimer & Terms", systemImage: "exclamationmark.triangle")
                        }
                        Link(destination: URL(string: "https://example.com/terms")!) {
                            Label("Terms of Use", systemImage: "doc.text")
                        }
                        // TODO: Replace with real terms URL before App Store submission
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

// MARK: - Disclaimer View

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("App Disclaimer")
                    .font(.title2.bold())
                    .padding(.bottom, 8)

                Group {
                    Text("By using this application, you acknowledge and agree that all run-tracking, workout analysis, distance estimates, and race-readiness assessments are provided for informational and educational purposes only. The app's outputs, including any guidance regarding readiness for 5K, 10K, half marathon, marathon, or any other race distance, are directional only and must not be treated as medical advice, health advice, or a guarantee of safety, performance, or suitability.")
                        .font(.body)
                        .lineSpacing(4)

                    Text("The readiness assessment is not a substitute for evaluation, advice, diagnosis, or treatment by a licensed physician, certified trainer, physical therapist, dietitian, or any other qualified professional. You are solely responsible for determining whether any running, training, or physical activity is appropriate for you based on your own health, fitness level, medical history, and current condition.")
                        .font(.body)
                        .lineSpacing(4)
                }

                Text("Assumption of Risk")
                    .font(.headline)
                    .padding(.top, 8)

                Text("Running and related physical activity involve inherent risks, including but not limited to slips, falls, collisions, overexertion, dehydration, heat illness, exhaustion, cardiac events, musculoskeletal injury, and other serious bodily injury or death. You agree that you will take all necessary precautions before, during, and after using this app or participating in any activity informed by this app, including choosing a safe environment, using proper equipment, following traffic and trail safety rules, staying aware of weather and terrain conditions, and stopping immediately if you feel pain, dizziness, shortness of breath, or any other concerning symptoms.")
                    .font(.body)
                    .lineSpacing(4)

                Text("You further acknowledge that any decision to run, train, increase mileage, attempt a race, or modify activity based on this app is made solely by you at your own risk.")
                    .font(.body)
                    .lineSpacing(4)

                Text("No Liability")
                    .font(.headline)
                    .padding(.top, 8)

                Text("To the maximum extent permitted by applicable law, the developer, owner, publisher, and affiliates of this app shall not be liable for any direct, indirect, incidental, special, consequential, exemplary, or punitive damages, losses, claims, liabilities, or expenses of any kind arising out of or related to your use of, or inability to use, this app. This includes, without limitation, any physical injury, mental distress, emotional harm, loss of income, loss of data, property damage, or financial loss resulting directly or indirectly from reliance on the app or its recommendations.")
                    .font(.body)
                    .lineSpacing(4)

                Text("The developer is not responsible for any harm, loss, or damage caused by misuse of the app, inaccurate or incomplete user-entered data, device malfunction, third-party services, environmental conditions, or any actions taken in reliance on the app's outputs.")
                    .font(.body)
                    .lineSpacing(4)

                Text("User Responsibility")
                    .font(.headline)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("You agree that you are solely responsible for:")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Using the app in a safe environment.")
                        Text("• Exercising appropriate caution while running or training.")
                        Text("• Ensuring your health and physical readiness before participating in any activity.")
                        Text("• Seeking professional medical or training advice where appropriate.")
                        Text("• Verifying the accuracy of any data you enter into the app.")
                        Text("• Following all applicable laws, traffic rules, and safety practices.")
                    }
                    .font(.body)
                    .padding(.leading, 8)
                }

                Text("Music and Device Use")
                    .font(.headline)
                    .padding(.top, 8)

                Text("If the app includes music playback or other audio features, you agree to use them responsibly and in a manner that does not distract you from your surroundings, traffic, pedestrians, or other hazards. The developer is not responsible for injuries or losses arising from distraction, unsafe use of headphones, device handling during exercise, or any related conduct.")
                    .font(.body)
                    .lineSpacing(4)

                Text("Acceptance")
                    .font(.headline)
                    .padding(.top, 8)

                Text("By downloading, installing, accessing, or using this app, you confirm that you have read, understood, and agree to this disclaimer and accept all risks associated with your use of the app.")
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding()
        }
        .navigationTitle("Disclaimer & Terms")
        .background(RunReadyGradient())
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
