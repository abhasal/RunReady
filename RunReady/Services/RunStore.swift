import Foundation
import SwiftData

/// Repository layer for RunWorkout persistence via SwiftData.
/// Inject via environment and call from ViewModels only.
@Observable
final class RunStore {

    // MARK: - Dependencies
    private var modelContext: ModelContext
    private let healthKitManager: HealthKitManager

    init(modelContext: ModelContext, healthKitManager: HealthKitManager = .shared) {
        self.modelContext = modelContext
        self.healthKitManager = healthKitManager
    }

    // MARK: - CRUD

    func save(_ run: RunWorkout) throws {
        modelContext.insert(run)
        try modelContext.save()
    }

    func delete(_ run: RunWorkout) throws {
        modelContext.delete(run)
        try modelContext.save()
    }

    func fetchAll(sortedBy: SortDescriptor<RunWorkout> = SortDescriptor(\.date, order: .reverse)) throws -> [RunWorkout] {
        let descriptor = FetchDescriptor<RunWorkout>(sortBy: [sortedBy])
        return try modelContext.fetch(descriptor)
    }

    func fetchRuns(from startDate: Date, to endDate: Date = Date()) throws -> [RunWorkout] {
        let predicate = #Predicate<RunWorkout> { run in
            run.date >= startDate && run.date <= endDate
        }
        let descriptor = FetchDescriptor<RunWorkout>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - HealthKit sync

    /// Import running workouts from HealthKit for the last `weeks` weeks.
    /// Skips workouts already imported (matched by healthKitWorkoutID).
    @discardableResult
    func syncFromHealthKit(weeks: Int = 52) async throws -> Int {
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: Date())!
        let hkWorkouts = try await healthKitManager.fetchRunningWorkouts(from: startDate)

        // Fetch existing HK IDs to avoid duplicates
        let existingIDs: Set<String> = try {
            let all = try fetchAll()
            return Set(all.compactMap(\.healthKitWorkoutID))
        }()

        var imported = 0
        for hkWorkout in hkWorkouts {
            let uid = hkWorkout.uuid.uuidString
            guard !existingIDs.contains(uid) else { continue }

            let run = healthKitManager.convertToRunWorkout(hkWorkout)

            // Attempt heart rate (non-fatal if unavailable)
            run.heartRateAvgBPM = try? await healthKitManager.fetchAverageHeartRate(for: hkWorkout)

            // Attempt route (non-fatal)
            let routePoints = (try? await healthKitManager.fetchRoutePoints(for: hkWorkout)) ?? []
            routePoints.forEach { run.routePoints.append($0) }

            modelContext.insert(run)
            imported += 1
        }

        if imported > 0 {
            try modelContext.save()
        }

        return imported
    }

    // MARK: - Analytics helpers

    func totalDistance(from start: Date, to end: Date = Date()) throws -> Double {
        let runs = try fetchRuns(from: start, to: end)
        return runs.reduce(0) { $0 + $1.distanceMeters }
    }

    func longestRun(from start: Date, to end: Date = Date()) throws -> RunWorkout? {
        let runs = try fetchRuns(from: start, to: end)
        return runs.max(by: { $0.distanceMeters < $1.distanceMeters })
    }

    func currentStreak() throws -> Int {
        let all = try fetchAll()
        guard !all.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let hasRun = all.contains { run in
                let day = calendar.startOfDay(for: run.date)
                return day == checkDate
            }
            if hasRun {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if checkDate == calendar.startOfDay(for: Date()) {
                // Today has no run — check yesterday before breaking
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                let _ = nextDay // suppress warning
                let hadRunYesterday = all.contains { run in
                    calendar.startOfDay(for: run.date) == checkDate
                }
                if hadRunYesterday {
                    continue
                } else {
                    break
                }
            } else {
                break
            }
        }
        return streak
    }
}
