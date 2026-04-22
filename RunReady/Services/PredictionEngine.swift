import Foundation

// MARK: - PredictionEngine
//
// Conservative, rule-based race readiness scoring.
//
// Algorithm overview (see ALGORITHM.md for full documentation):
//
//  1. Build a TrainingWindow from the provided run history.
//  2. For each RaceDistance, compute weighted sub-scores (0–1 each):
//       a. Long-run score  — longest run in last 4 weeks vs requirement
//       b. Volume score    — avg weekly km in last 4 weeks vs requirement
//       c. Frequency score — avg runs/week in last 8 weeks vs requirement
//       d. Consistency score — active weeks in last 12 vs requirement
//       e. Safety modifier — penalizes recent training spikes (>40% weekly jump)
//  3. Composite score = weighted average * 100, capped at 100.
//  4. Map score → ReadinessTier:
//       < 40   → .notReady
//       40–64  → .buildBase
//       65–84  → .nearlyReady
//       >= 85  → .safelyReady
//  5. The recommended distance = highest distance with tier .safelyReady.
//  6. Suggestions are generated for each unmet criterion.

final class PredictionEngine {

    // MARK: Factor weights (must sum to 1.0)
    private struct Weights {
        static let longRun    = 0.35
        static let volume     = 0.30
        static let frequency  = 0.20
        static let consistency = 0.15
    }

    // MARK: - Public API

    /// Compute a full ReadinessAssessment from a history of runs.
    /// - Parameter runs: All stored runs, in any order.
    /// - Parameter now:  Injectable for unit testing; defaults to Date()
    func assess(runs: [RunWorkout], now: Date = Date()) -> ReadinessAssessment {
        let window = buildWindow(runs: runs, now: now)
        var scores: [RaceDistance: RaceReadinessScore] = [:]

        for distance in RaceDistance.allCases {
            scores[distance] = scoreDistance(distance, window: window)
        }

        let recommended = RaceDistance.allCases
            .filter { scores[$0]?.tier == .safelyReady }
            .max(by: { $0.sortOrder < $1.sortOrder })

        let nextTarget: RaceDistance?
        if let rec = recommended {
            nextTarget = rec.next
        } else {
            // Not ready for anything yet — suggest the closest one
            nextTarget = RaceDistance.allCases.first
        }

        return ReadinessAssessment(
            assessedAt: now,
            scores: scores,
            recommendedDistance: recommended,
            nextTargetDistance: nextTarget
        )
    }

    // MARK: - Private: window construction

    private func buildWindow(runs: [RunWorkout], now: Date) -> TrainingWindow {
        let cal = Calendar.current
        func dateAgo(weeks: Int) -> Date {
            cal.date(byAdding: .weekOfYear, value: -weeks, to: now)!
        }
        let w2  = dateAgo(weeks: 2)
        let w4  = dateAgo(weeks: 4)
        let w8  = dateAgo(weeks: 8)
        let w12 = dateAgo(weeks: 12)

        return TrainingWindow(
            runs2Weeks:  runs.filter { $0.date >= w2  },
            runs4Weeks:  runs.filter { $0.date >= w4  },
            runs8Weeks:  runs.filter { $0.date >= w8  },
            runs12Weeks: runs.filter { $0.date >= w12 }
        )
    }

    // MARK: - Private: per-distance scoring

    private func scoreDistance(_ distance: RaceDistance, window: TrainingWindow) -> RaceReadinessScore {
        let req = distance.requirements
        var factors: [ReadinessFactor] = []

        // --- 1. Long run score ---
        let longestRun = window.longestRunIn4WeeksMeters
        let longRunRatio = min(longestRun / req.minLongRunMeters, 1.0)
        let longRunDetail: String
        if longRunRatio >= 1.0 {
            longRunDetail = "Your longest recent run meets the requirement."
        } else {
            let needed = req.minLongRunMeters - longestRun
            longRunDetail = "Need \(formattedMeters(needed)) more on a long run."
        }
        factors.append(ReadinessFactor(
            name: "Long Run",
            score: longRunRatio,
            weight: Weights.longRun,
            detail: longRunDetail
        ))

        // --- 2. Volume score ---
        let weeklyAvg = window.weeklyAverageMetersLast4Weeks
        let volumeRatio = min(weeklyAvg / req.minWeeklyAvgMeters, 1.0)
        let volumeDetail: String
        if volumeRatio >= 1.0 {
            volumeDetail = "Weekly mileage is on track."
        } else {
            let deficit = req.minWeeklyAvgMeters - weeklyAvg
            volumeDetail = "Build \(formattedMeters(deficit))/week more on average."
        }
        factors.append(ReadinessFactor(
            name: "Weekly Volume",
            score: volumeRatio,
            weight: Weights.volume,
            detail: volumeDetail
        ))

        // --- 3. Frequency score ---
        let avgRunsPerWeek = window.weeklyRunCountAvgLast8Weeks
        let freqRatio = min(avgRunsPerWeek / req.minRunsPerWeek, 1.0)
        let freqDetail: String
        if freqRatio >= 1.0 {
            freqDetail = "You're running frequently enough."
        } else {
            let shortfall = req.minRunsPerWeek - avgRunsPerWeek
            freqDetail = String(format: "Add %.1f more run(s) per week.", shortfall)
        }
        factors.append(ReadinessFactor(
            name: "Frequency",
            score: freqRatio,
            weight: Weights.frequency,
            detail: freqDetail
        ))

        // --- 4. Consistency score ---
        let activeWeeks = window.activeWeeksIn12
        let consistencyRatio = min(Double(activeWeeks) / Double(req.minActiveWeeksIn12), 1.0)
        let consistencyDetail: String
        if consistencyRatio >= 1.0 {
            consistencyDetail = "Training has been consistent over 12 weeks."
        } else {
            let shortWeeks = req.minActiveWeeksIn12 - activeWeeks
            consistencyDetail = "Need \(shortWeeks) more active week(s) over the last 12 weeks."
        }
        factors.append(ReadinessFactor(
            name: "Consistency",
            score: consistencyRatio,
            weight: Weights.consistency,
            detail: consistencyDetail
        ))

        // --- 5. Raw weighted composite ---
        var composite = factors.reduce(0.0) { $0 + $1.weightedScore }

        // Safety penalty: if there's a training spike, cap at 70
        if window.hasTrainingSpike {
            composite = min(composite, 0.70)
        }

        // If there are no runs at all in 4 weeks, floor to 0
        if window.runs4Weeks.isEmpty {
            composite = 0
        }

        let finalScore = composite * 100.0

        let tier: ReadinessTier
        switch finalScore {
        case 85...:    tier = .safelyReady
        case 65..<85:  tier = .nearlyReady
        case 40..<65:  tier = .buildBase
        default:       tier = .notReady
        }

        let suggestions = buildSuggestions(factors: factors, distance: distance, window: window, spike: window.hasTrainingSpike)

        return RaceReadinessScore(
            distance: distance,
            score: finalScore,
            tier: tier,
            factors: factors,
            suggestions: suggestions
        )
    }

    // MARK: - Suggestion generation

    private func buildSuggestions(
        factors: [ReadinessFactor],
        distance: RaceDistance,
        window: TrainingWindow,
        spike: Bool
    ) -> [String] {
        var suggestions: [String] = []
        let req = distance.requirements

        if spike {
            suggestions.append("Your training volume jumped significantly last week. Allow 1–2 easy weeks to absorb the load before a race.")
        }

        for factor in factors where factor.score < 1.0 {
            suggestions.append(factor.detail)
        }

        if window.runs4Weeks.isEmpty {
            suggestions.append("Start with short, easy runs consistently before targeting \(distance.shortLabel).")
        } else if window.runs8Weeks.count < 4 {
            suggestions.append("Aim for at least \(Int(req.minRunsPerWeek.rounded())) runs per week for 8 consecutive weeks.")
        }

        return suggestions
    }

    // MARK: - Formatting helpers (internal only)

    private func formattedMeters(_ meters: Double) -> String {
        let km = meters / 1000.0
        if km >= 1 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
}
