import Foundation

// MARK: - Readiness Tier

enum ReadinessTier: String, Codable, Comparable {
    case notReady     = "Not Ready"
    case buildBase    = "Build Base"
    case nearlyReady  = "Nearly Ready"
    case safelyReady  = "Safely Ready"

    var sortIndex: Int {
        switch self {
        case .notReady:    return 0
        case .buildBase:   return 1
        case .nearlyReady: return 2
        case .safelyReady: return 3
        }
    }

    static func < (lhs: ReadinessTier, rhs: ReadinessTier) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }

    var color: String {   // SwiftUI Color name — used in views
        switch self {
        case .notReady:    return "ReadinessRed"
        case .buildBase:   return "ReadinessOrange"
        case .nearlyReady: return "ReadinessYellow"
        case .safelyReady: return "ReadinessGreen"
        }
    }

    var label: String { rawValue }

    var icon: String {
        switch self {
        case .notReady:    return "xmark.circle.fill"
        case .buildBase:   return "arrow.up.circle"
        case .nearlyReady: return "clock.fill"
        case .safelyReady: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Individual scoring factor

struct ReadinessFactor: Identifiable {
    let id: UUID = UUID()
    let name: String
    /// 0.0 – 1.0, where 1.0 means fully meeting this criterion
    let score: Double
    /// Weight in the total score computation
    let weight: Double
    let detail: String

    var weightedScore: Double { score * weight }
}

// MARK: - Per-distance result

struct RaceReadinessScore: Identifiable {
    let id: UUID = UUID()
    let distance: RaceDistance
    /// 0–100 composite score
    let score: Double
    let tier: ReadinessTier
    let factors: [ReadinessFactor]
    let suggestions: [String]

    var isReady: Bool { tier == .safelyReady }
    var progressFraction: Double { min(score / 100.0, 1.0) }
}

// MARK: - Full assessment

struct ReadinessAssessment {
    let assessedAt: Date
    let scores: [RaceDistance: RaceReadinessScore]
    /// Highest distance the runner is considered safely ready for
    let recommendedDistance: RaceDistance?
    /// The next distance they are working toward
    let nextTargetDistance: RaceDistance?

    /// Returns scores in ascending order of distance
    var orderedScores: [RaceReadinessScore] {
        RaceDistance.allCases.compactMap { scores[$0] }
    }

    static var empty: ReadinessAssessment {
        ReadinessAssessment(
            assessedAt: Date(),
            scores: [:],
            recommendedDistance: nil,
            nextTargetDistance: nil
        )
    }
}

// MARK: - Training window data (input to engine)

struct TrainingWindow {
    let runs2Weeks: [RunWorkout]
    let runs4Weeks: [RunWorkout]
    let runs8Weeks: [RunWorkout]
    let runs12Weeks: [RunWorkout]

    var longestRunIn4WeeksMeters: Double {
        runs4Weeks.map(\.distanceMeters).max() ?? 0
    }

    var weeklyAverageMetersLast4Weeks: Double {
        guard !runs4Weeks.isEmpty else { return 0 }
        return runs4Weeks.reduce(0) { $0 + $1.distanceMeters } / 4.0
    }

    var weeklyRunCountAvgLast8Weeks: Double {
        guard !runs8Weeks.isEmpty else { return 0 }
        return Double(runs8Weeks.count) / 8.0
    }

    var activeWeeksIn12: Int {
        guard !runs12Weeks.isEmpty else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        var activeCount = 0
        for week in 0..<12 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -week - 1, to: now)!
            let weekEnd   = calendar.date(byAdding: .weekOfYear, value: -week, to: now)!
            let hasRun = runs12Weeks.contains { $0.date >= weekStart && $0.date < weekEnd }
            if hasRun { activeCount += 1 }
        }
        return activeCount
    }

    /// Detect training spikes: compare last-week volume to prior 3-week average
    var hasTrainingSpike: Bool {
        let calendar = Calendar.current
        let now = Date()
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: now)!

        let lastWeekTotal = runs4Weeks
            .filter { $0.date >= oneWeekAgo }
            .reduce(0.0) { $0 + $1.distanceMeters }

        let priorThreeWeekRuns = runs4Weeks.filter { $0.date >= fourWeeksAgo && $0.date < oneWeekAgo }
        guard !priorThreeWeekRuns.isEmpty else { return false }
        let priorAvgWeekly = priorThreeWeekRuns.reduce(0.0) { $0 + $1.distanceMeters } / 3.0

        guard priorAvgWeekly > 0 else { return false }
        return (lastWeekTotal / priorAvgWeekly) > 1.4  // >40% spike
    }
}
