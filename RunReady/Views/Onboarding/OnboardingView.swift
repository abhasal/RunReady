import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var isRequestingPermissions = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "exclamationmark.triangle.fill",
            color: .orange,
            title: "Important Disclaimer",
            description: "This app provides informational run-tracking and race-readiness estimates only. It is not medical, fitness, or nutrition advice. Race readiness is directional and not a guarantee that you are physically prepared for any race. Always consult a physician, trainer, or dietitian before making training decisions. Running involves risk, and you are responsible for your own safety and precautions. To the fullest extent permitted by law, the developer is not liable for any injury, loss, or damage resulting from use of this app."
        ),
        OnboardingPage(
            icon: "figure.run",
            color: .blue,
            title: "Track Every Run",
            description: "Log runs automatically from Apple Health or track live with GPS. Manual entry is always available."
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            color: .green,
            title: "Race Readiness",
            description: "Our conservative algorithm analyzes your training history to tell you which race distances you can safely attempt today."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            color: .purple,
            title: "Understand Your Training",
            description: "Weekly trends, monthly volume, streaks, and personal records — all in one place."
        ),
        OnboardingPage(
            icon: "music.note",
            color: .orange,
            title: "Music While You Run",
            description: "Play your running playlist directly from the app. Background audio keeps the beat while GPS tracks your route."
        )
    ]

    var body: some View {
        ZStack {
            RunReadyGradient()

            VStack(spacing: 0) {
                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    Text("RunReady")
                        .font(.largeTitle.bold())
                }
                .padding(.top, 60)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 340)

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    if currentPage == pages.count - 1 {
                        Button {
                            Task { await requestPermissionsAndContinue() }
                        } label: {
                            HStack {
                                if isRequestingPermissions {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Get Started")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isRequestingPermissions)
                    } else {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button("Skip setup") {
                        appState.completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func requestPermissionsAndContinue() async {
        isRequestingPermissions = true
        try? await appState.healthKitManager.requestAuthorization()
        isRequestingPermissions = false
        appState.completeOnboarding()
    }
}

// MARK: - Sub-types

struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(page.color)
            }
            Text(page.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 24)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
