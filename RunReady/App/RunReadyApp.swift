import SwiftUI
import SwiftData

@main
struct RunReadyApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(appState.preferences)
        }
        .modelContainer(for: [RunWorkout.self, RoutePoint.self])
    }
}
