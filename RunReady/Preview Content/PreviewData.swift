import Foundation
import SwiftData

/// Deterministic preview/test data. Never used in production builds.
enum PreviewData {

    // MARK: - In-memory SwiftData container

    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([RunWorkout.self, RoutePoint.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let ctx = container.mainContext
        for run in sampleRuns {
            ctx.insert(run)
        }
        try? ctx.save()
        return container
    }()

    // MARK: - Sample runs

    static var sampleRuns: [RunWorkout] {
        let calendar = Calendar.current
        let now = Date()

        func daysAgo(_ n: Int) -> Date {
            calendar.date(byAdding: .day, value: -n, to: now)!
        }

        return [
            // Last 7 days
            RunWorkout(date: daysAgo(0), duration: 30 * 60, distanceMeters: 5_100, calories: 320, notes: "Easy morning run", sourceType: .liveTracked),
            RunWorkout(date: daysAgo(2), duration: 25 * 60, distanceMeters: 4_200, calories: 270, sourceType: .manual),
            RunWorkout(date: daysAgo(4), duration: 55 * 60, distanceMeters: 9_500, calories: 600, notes: "Long run, felt strong", sourceType: .healthKit),
            RunWorkout(date: daysAgo(6), duration: 28 * 60, distanceMeters: 4_800, sourceType: .manual),

            // 1-2 weeks ago
            RunWorkout(date: daysAgo(8),  duration: 32 * 60, distanceMeters: 5_500, sourceType: .healthKit),
            RunWorkout(date: daysAgo(10), duration: 22 * 60, distanceMeters: 3_800, sourceType: .manual),
            RunWorkout(date: daysAgo(12), duration: 50 * 60, distanceMeters: 8_700, calories: 550, notes: "Tempo workout", sourceType: .healthKit),
            RunWorkout(date: daysAgo(14), duration: 29 * 60, distanceMeters: 4_900, sourceType: .manual),

            // 2-4 weeks ago
            RunWorkout(date: daysAgo(16), duration: 35 * 60, distanceMeters: 6_000, sourceType: .manual),
            RunWorkout(date: daysAgo(18), duration: 26 * 60, distanceMeters: 4_400, sourceType: .healthKit),
            RunWorkout(date: daysAgo(20), duration: 60 * 60, distanceMeters: 10_500, calories: 680, notes: "10K PR attempt", sourceType: .liveTracked),
            RunWorkout(date: daysAgo(22), duration: 30 * 60, distanceMeters: 5_000, sourceType: .manual),
            RunWorkout(date: daysAgo(24), duration: 24 * 60, distanceMeters: 4_100, sourceType: .healthKit),
            RunWorkout(date: daysAgo(26), duration: 52 * 60, distanceMeters: 9_000, sourceType: .manual),

            // 5-8 weeks ago
            RunWorkout(date: daysAgo(33), duration: 33 * 60, distanceMeters: 5_700, sourceType: .healthKit),
            RunWorkout(date: daysAgo(37), duration: 27 * 60, distanceMeters: 4_600, sourceType: .manual),
            RunWorkout(date: daysAgo(40), duration: 58 * 60, distanceMeters: 9_800, sourceType: .healthKit),
            RunWorkout(date: daysAgo(44), duration: 31 * 60, distanceMeters: 5_200, sourceType: .manual),
            RunWorkout(date: daysAgo(48), duration: 23 * 60, distanceMeters: 3_900, sourceType: .healthKit),
            RunWorkout(date: daysAgo(54), duration: 45 * 60, distanceMeters: 7_800, sourceType: .manual),

            // 9-12 weeks ago
            RunWorkout(date: daysAgo(61), duration: 28 * 60, distanceMeters: 4_700, sourceType: .healthKit),
            RunWorkout(date: daysAgo(68), duration: 55 * 60, distanceMeters: 9_200, sourceType: .manual),
            RunWorkout(date: daysAgo(75), duration: 32 * 60, distanceMeters: 5_400, sourceType: .healthKit),
            RunWorkout(date: daysAgo(82), duration: 20 * 60, distanceMeters: 3_500, sourceType: .manual),
        ]
    }

    // MARK: - Scenario sets for unit tests

    /// Beginner: only a few short runs in the last 2 weeks
    static var beginnerRuns: [RunWorkout] {
        let cal = Calendar.current
        let now = Date()
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        return [
            RunWorkout(date: ago(3), duration: 15 * 60, distanceMeters: 2_000, sourceType: .manual),
            RunWorkout(date: ago(10), duration: 18 * 60, distanceMeters: 2_500, sourceType: .manual),
        ]
    }

    /// 5K ready
    static var fiveKReadyRuns: [RunWorkout] {
        let cal = Calendar.current
        let now = Date()
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        var runs: [RunWorkout] = []
        // 8 weeks of 3 runs/week, average 6–7 km, long run ~5 km
        for week in 0..<8 {
            for run in 0..<3 {
                let daysBack = week * 7 + run * 2 + 1
                let distance = run == 2 ? 5_100.0 : 3_500.0
                runs.append(RunWorkout(
                    date: ago(daysBack),
                    duration: distance / 2.5,
                    distanceMeters: distance,
                    sourceType: .manual
                ))
            }
        }
        return runs
    }

    /// 10K ready
    static var tenKReadyRuns: [RunWorkout] {
        let cal = Calendar.current
        let now = Date()
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        var runs: [RunWorkout] = []
        for week in 0..<10 {
            let longDist: Double = week < 4 ? 7_000 : 9_000
            for run in 0..<4 {
                let daysBack = week * 7 + run * 2 + 1
                let dist = run == 3 ? longDist : 4_500.0
                runs.append(RunWorkout(date: ago(daysBack), duration: dist / 2.8, distanceMeters: dist, sourceType: .manual))
            }
        }
        return runs
    }

    /// Close to half marathon
    static var halfMarathonNearlyReadyRuns: [RunWorkout] {
        let cal = Calendar.current
        let now = Date()
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        var runs: [RunWorkout] = []
        for week in 0..<10 {
            let longDist: Double = week < 4 ? 11_000 : 13_500
            for run in 0..<4 {
                let daysBack = week * 7 + run * 2 + 1
                let dist = run == 3 ? longDist : 6_000.0
                runs.append(RunWorkout(date: ago(daysBack), duration: dist / 3.0, distanceMeters: dist, sourceType: .manual))
            }
        }
        return runs
    }

    /// Marathon-ready experienced runner
    static var marathonReadyRuns: [RunWorkout] {
        let cal = Calendar.current
        let now = Date()
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        var runs: [RunWorkout] = []
        for week in 0..<14 {
            let longDist: Double = week < 6 ? 20_000 : 29_000
            for run in 0..<6 {
                let daysBack = week * 7 + run + 1
                let dist = run == 5 ? longDist : 10_000.0
                runs.append(RunWorkout(date: ago(daysBack), duration: dist / 3.2, distanceMeters: dist, sourceType: .manual))
            }
        }
        return runs
    }
}
