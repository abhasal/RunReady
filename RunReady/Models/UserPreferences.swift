import Foundation
import Observation

enum UnitSystem: String, CaseIterable, Codable {
    case metric   = "Kilometers"
    case imperial = "Miles"

    var distanceUnit: String {
        switch self {
        case .metric:   return "km"
        case .imperial: return "mi"
        }
    }

    var paceUnit: String {
        switch self {
        case .metric:   return "min/km"
        case .imperial: return "min/mi"
        }
    }
}

/// Persistent user preferences backed by UserDefaults via @AppStorage-compatible keys.
/// Shared via the environment as an @Observable class.
@Observable
final class UserPreferences {

    // MARK: Keys
    private enum Key {
        static let unitSystem            = "pref_unitSystem"
        static let hasCompletedOnboarding = "pref_hasCompletedOnboarding"
        static let showHeartRate         = "pref_showHeartRate"
        static let enableRunReminders    = "pref_enableRunReminders"
    }

    var unitSystem: UnitSystem {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: Key.unitSystem) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    var showHeartRate: Bool {
        didSet { UserDefaults.standard.set(showHeartRate, forKey: Key.showHeartRate) }
    }

    var enableRunReminders: Bool {
        didSet { UserDefaults.standard.set(enableRunReminders, forKey: Key.enableRunReminders) }
    }

    init() {
        let defaults = UserDefaults.standard
        let rawUnit = defaults.string(forKey: Key.unitSystem) ?? UnitSystem.imperial.rawValue
        self.unitSystem            = UnitSystem(rawValue: rawUnit) ?? .imperial
        self.hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        self.showHeartRate         = defaults.bool(forKey: Key.showHeartRate)
        self.enableRunReminders    = defaults.bool(forKey: Key.enableRunReminders)
    }
}
