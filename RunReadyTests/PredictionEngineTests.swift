import XCTest
@testable import RunReady

final class PredictionEngineTests: XCTestCase {

    private let engine = PredictionEngine()
    private let fixedDate: Date = {
        // Use a fixed "now" so tests are deterministic
        var components = DateComponents()
        components.year = 2025; components.month = 6; components.day = 1
        return Calendar.current.date(from: components)!
    }()

    // MARK: - Beginner: inconsistent short runs

    func testBeginner_notReadyForAnything() {
        let runs = makeRuns(scenario: .beginner)
        let assessment = engine.assess(runs: runs, now: fixedDate)

        XCTAssertNil(assessment.recommendedDistance, "Beginner should have no safe distance")
        for (_, score) in assessment.scores {
            XCTAssertLessThan(score.score, 65, "Beginner score should be below nearlyReady threshold")
        }
    }

    // MARK: - 5K ready

    func testFiveKRunner_safelyReadyForFiveK() {
        let runs = makeRuns(scenario: .fiveKReady)
        let assessment = engine.assess(runs: runs, now: fixedDate)

        let fiveKScore = assessment.scores[.fiveK]!
        XCTAssertGreaterThanOrEqual(fiveKScore.score, 85, "5K-ready runner should score ≥85 for 5K")
        XCTAssertEqual(fiveKScore.tier, .safelyReady)

        // Should NOT be ready for marathon yet
        let marathonScore = assessment.scores[.marathon]!
        XCTAssertLessThan(marathonScore.score, 65)
    }

    // MARK: - 10K ready

    func testTenKRunner_safelyReadyForTenK() {
        let runs = makeRuns(scenario: .tenKReady)
        let assessment = engine.assess(runs: runs, now: fixedDate)

        let tenKScore = assessment.scores[.tenK]!
        XCTAssertGreaterThanOrEqual(tenKScore.score, 85)
        XCTAssertEqual(tenKScore.tier, .safelyReady)
    }

    func testTenKRunner_recommendedDistanceIsTenKOrHigher() {
        let runs = makeRuns(scenario: .tenKReady)
        let assessment = engine.assess(runs: runs, now: fixedDate)

        guard let recommended = assessment.recommendedDistance else {
            XCTFail("Should have a recommended distance")
            return
        }
        XCTAssertGreaterThanOrEqual(recommended.sortOrder, RaceDistance.tenK.sortOrder)
    }

    // MARK: - Half marathon nearly ready

    func testHalfMarathonNearlyReady_nearlyReadyTier() {
        let runs = makeRuns(scenario: .halfNearlyReady)
        let assessment = engine.assess(runs: runs, now: fixedDate)

        let halfScore = assessment.scores[.halfMarathon]!
        // Should be in the nearlyReady range (65–84)
        XCTAssertGreaterThanOrEqual(halfScore.score, 60,
            "Half-marathon training should produce a meaningful score")
    }

    // MARK: - Marathon ready

    func testMarathonRunner_safelyReadyForMarathon() {
        let runs = makeRuns(scenario: .marathonReady)
        let assessment = engine.assess(runs: runs, now: fixedDate)

        let marathonScore = assessment.scores[.marathon]!
        XCTAssertGreaterThanOrEqual(marathonScore.score, 85)
        XCTAssertEqual(marathonScore.tier, .safelyReady)
        XCTAssertEqual(assessment.recommendedDistance, .marathon)
    }

    // MARK: - Training spike penalizes score

    func testTrainingSpike_capsScore() {
        // Start with a decent 10K runner base
        var runs = makeRuns(scenario: .tenKReady)

        // Add a massive spike in the last week (3× normal volume)
        let cal = Calendar.current
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: -i, to: fixedDate)!
            runs.append(RunWorkout(date: d, duration: 90 * 60, distanceMeters: 25_000, sourceType: .manual))
        }

        let assessment = engine.assess(runs: runs, now: fixedDate)
        for (_, score) in assessment.scores {
            XCTAssertLessThanOrEqual(score.score, 70.1,
                "Training spike should cap composite score at 70")
        }
    }

    // MARK: - No runs produces empty assessment

    func testNoRuns_allScoresBelowThreshold() {
        let assessment = engine.assess(runs: [], now: fixedDate)
        XCTAssertNil(assessment.recommendedDistance)
        for (_, score) in assessment.scores {
            XCTAssertEqual(score.score, 0, accuracy: 0.1)
            XCTAssertEqual(score.tier, .notReady)
        }
    }

    // MARK: - Scores are deterministic

    func testDeterminism() {
        let runs = makeRuns(scenario: .tenKReady)
        let a1 = engine.assess(runs: runs, now: fixedDate)
        let a2 = engine.assess(runs: runs, now: fixedDate)
        for distance in RaceDistance.allCases {
            XCTAssertEqual(a1.scores[distance]?.score, a2.scores[distance]?.score,
                accuracy: 0.001, "Score for \(distance) should be deterministic")
        }
    }

    // MARK: - Factors have sensible weight sum

    func testFactorWeightSum() {
        let runs = makeRuns(scenario: .tenKReady)
        let assessment = engine.assess(runs: runs, now: fixedDate)
        let score = assessment.scores[.tenK]!
        let totalWeight = score.factors.reduce(0.0) { $0 + $1.weight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.001, "Factor weights must sum to 1.0")
    }

    // MARK: - Scenario factory

    private enum Scenario {
        case beginner, fiveKReady, tenKReady, halfNearlyReady, marathonReady
    }

    private func makeRuns(scenario: Scenario) -> [RunWorkout] {
        let cal = Calendar.current
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: fixedDate)! }

        switch scenario {
        case .beginner:
            return [
                RunWorkout(date: ago(3),  duration: 15 * 60, distanceMeters: 2_000, sourceType: .manual),
                RunWorkout(date: ago(10), duration: 18 * 60, distanceMeters: 2_500, sourceType: .manual),
            ]

        case .fiveKReady:
            var runs: [RunWorkout] = []
            for week in 0..<8 {
                for run in 0..<3 {
                    let dist: Double = run == 2 ? 5_100 : 3_500
                    runs.append(RunWorkout(date: ago(week * 7 + run * 2 + 1),
                                           duration: dist / 2.5, distanceMeters: dist, sourceType: .manual))
                }
            }
            return runs

        case .tenKReady:
            var runs: [RunWorkout] = []
            for week in 0..<10 {
                let longDist: Double = week < 5 ? 7_500 : 9_200
                for run in 0..<4 {
                    let dist = run == 3 ? longDist : 4_800.0
                    runs.append(RunWorkout(date: ago(week * 7 + run * 2 + 1),
                                           duration: dist / 2.8, distanceMeters: dist, sourceType: .manual))
                }
            }
            return runs

        case .halfNearlyReady:
            var runs: [RunWorkout] = []
            for week in 0..<10 {
                let longDist: Double = week < 5 ? 11_500 : 13_800
                for run in 0..<4 {
                    let dist = run == 3 ? longDist : 6_200.0
                    runs.append(RunWorkout(date: ago(week * 7 + run * 2 + 1),
                                           duration: dist / 3.0, distanceMeters: dist, sourceType: .manual))
                }
            }
            return runs

        case .marathonReady:
            var runs: [RunWorkout] = []
            for week in 0..<14 {
                let longDist: Double = week < 7 ? 22_000 : 30_000
                for run in 0..<6 {
                    let dist = run == 5 ? longDist : 11_000.0
                    runs.append(RunWorkout(date: ago(week * 7 + run + 1),
                                           duration: dist / 3.2, distanceMeters: dist, sourceType: .manual))
                }
            }
            return runs
        }
    }
}
