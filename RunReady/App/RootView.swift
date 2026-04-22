import SwiftUI

/// Root navigation container. Shows onboarding sheet if not completed;
/// otherwise shows the main tab bar with a persistent music mini-player.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .bottom) {
            mainTabView

            // Persistent mini-player above tab bar
            VStack(spacing: 0) {
                MiniPlayerView()
                    .padding(.bottom, 4)
                Spacer().frame(height: 49) // approximate tab bar height
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.isShowingOnboarding },
            set: { _ in }
        )) {
            OnboardingView()
        }
    }

    private var mainTabView: some View {
        @Bindable var state = appState
        return TabView(selection: $state.selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: AppTab.dashboard.systemImage) }
                .tag(AppTab.dashboard)

            RunHistoryView()
                .tabItem { Label("History", systemImage: AppTab.history.systemImage) }
                .tag(AppTab.history)

            ReadinessView()
                .tabItem { Label("Readiness", systemImage: AppTab.readiness.systemImage) }
                .tag(AppTab.readiness)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: AppTab.analytics.systemImage) }
                .tag(AppTab.analytics)

            SettingsView()
                .tabItem { Label("Settings", systemImage: AppTab.settings.systemImage) }
                .tag(AppTab.settings)
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
