import Foundation
import SwiftData
import Observation

/// Central app state shared via SwiftUI environment.
/// Holds references to all singleton services.
@Observable
final class AppState {

    let preferences: UserPreferences
    let healthKitManager: HealthKitManager
    let audioPlayer: AudioPlaybackManager
    let predictionEngine: PredictionEngine

    var isShowingOnboarding: Bool
    var selectedTab: AppTab = .dashboard

    init() {
        let prefs = UserPreferences()
        self.preferences = prefs
        self.healthKitManager = HealthKitManager.shared
        self.audioPlayer = AudioPlaybackManager()
        self.predictionEngine = PredictionEngine()
        self.isShowingOnboarding = !prefs.hasCompletedOnboarding
    }

    func completeOnboarding() {
        preferences.hasCompletedOnboarding = true
        isShowingOnboarding = false
    }
}

enum AppTab: String, CaseIterable {
    case dashboard  = "Dashboard"
    case history    = "History"
    case readiness  = "Readiness"
    case analytics  = "Analytics"
    case settings   = "Settings"

    var systemImage: String {
        switch self {
        case .dashboard:  return "house.fill"
        case .history:    return "list.bullet"
        case .readiness:  return "checkmark.seal.fill"
        case .analytics:  return "chart.bar.fill"
        case .settings:   return "gearshape.fill"
        }
    }
}
