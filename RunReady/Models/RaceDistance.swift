import Foundation

enum RaceDistance: String, CaseIterable, Codable, Identifiable {
    case fiveK       = "5K"
    case tenK        = "10K"
    case fifteenK    = "15K"
    case halfMarathon = "Half Marathon"
    case marathon    = "Marathon"

    var id: String { rawValue }

    /// Canonical distance in meters
    var meters: Double {
        switch self {
        case .fiveK:        return 5_000
        case .tenK:         return 10_000
        case .fifteenK:     return 15_000
        case .halfMarathon: return 21_097.5
        case .marathon:     return 42_195
        }
    }

    var shortLabel: String { rawValue }

    var emoji: String {
        switch self {
        case .fiveK:        return "🏃"
        case .tenK:         return "🏃‍♂️"
        case .fifteenK:     return "⚡️"
        case .halfMarathon: return "🥈"
        case .marathon:     return "🏅"
        }
    }

    var sortOrder: Int {
        switch self {
        case .fiveK: return 0
        case .tenK: return 1
        case .fifteenK: return 2
        case .halfMarathon: return 3
        case .marathon: return 4
        }
    }

    var next: RaceDistance? {
        let all = RaceDistance.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    var previous: RaceDistance? {
        let all = RaceDistance.allCases
        guard let idx = all.firstIndex(of: self), idx > 0 else { return nil }
        return all[idx - 1]
    }
}

// MARK: - Training requirements for a conservative readiness assessment
extension RaceDistance {
    struct Requirements {
        /// Minimum long run distance in meters (must appear within last 4 weeks)
        let minLongRunMeters: Double
        /// Minimum average weekly distance in meters (over last 4 weeks)
        let minWeeklyAvgMeters: Double
        /// Minimum average runs per week (over last 8 weeks)
        let minRunsPerWeek: Double
        /// Minimum total runs in last 8 weeks
        let minTotalRunsIn8Weeks: Int
        /// Minimum consistent weeks with runs (out of last 12 weeks)
        let minActiveWeeksIn12: Int
    }

    var requirements: Requirements {
        switch self {
        case .fiveK:
            return Requirements(
                minLongRunMeters: 4_000,
                minWeeklyAvgMeters: 8_000,
                minRunsPerWeek: 2.0,
                minTotalRunsIn8Weeks: 8,
                minActiveWeeksIn12: 4
            )
        case .tenK:
            return Requirements(
                minLongRunMeters: 8_000,
                minWeeklyAvgMeters: 20_000,
                minRunsPerWeek: 3.0,
                minTotalRunsIn8Weeks: 16,
                minActiveWeeksIn12: 6
            )
        case .fifteenK:
            return Requirements(
                minLongRunMeters: 11_000,
                minWeeklyAvgMeters: 24_000,
                minRunsPerWeek: 3.0,
                minTotalRunsIn8Weeks: 18,
                minActiveWeeksIn12: 8
            )
        case .halfMarathon:
            return Requirements(
                minLongRunMeters: 14_500,
                minWeeklyAvgMeters: 32_000,
                minRunsPerWeek: 4.0,
                minTotalRunsIn8Weeks: 24,
                minActiveWeeksIn12: 9
            )
        case .marathon:
            return Requirements(
                minLongRunMeters: 29_000,
                minWeeklyAvgMeters: 56_000,
                minRunsPerWeek: 5.0,
                minTotalRunsIn8Weeks: 32,
                minActiveWeeksIn12: 11
            )
        }
    }
}
