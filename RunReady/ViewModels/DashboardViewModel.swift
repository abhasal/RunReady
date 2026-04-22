import Foundation
import SwiftData
import Observation

@Observable
final class DashboardViewModel {

    // MARK: - State
    var todayDistance: Double = 0
    var weekDistance: Double = 0
    var monthDistance: Double = 0
    var yearDistance: Double = 0
    var totalRuns: Int = 0
    var latestRun: RunWorkout?
    var readinessAssessment: ReadinessAssessment = .empty
    var streak: Int = 0
    var isLoadingHealthKit: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let predictionEngine: PredictionEngine
    private let healthKitManager: HealthKitManager

    init(predictionEngine: PredictionEngine = PredictionEngine(),
         healthKitManager: HealthKitManager = .shared) {
        self.predictionEngine = predictionEngine
        self.healthKitManager = healthKitManager
    }

    // MARK: - Load

    func load(from modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay   = calendar.startOfDay(for: now)
        let startOfWeek  = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfYear  = calendar.date(from: calendar.dateComponents([.year], from: now))!
        let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: now)!

        do {
            let store = RunStore(modelContext: modelContext)
            todayDistance  = try store.totalDistance(from: startOfDay)
            weekDistance   = try store.totalDistance(from: startOfWeek)
            monthDistance  = try store.totalDistance(from: startOfMonth)
            yearDistance   = try store.totalDistance(from: startOfYear)
            streak         = try store.currentStreak()
            let allRuns    = try store.fetchAll()
            totalRuns      = allRuns.count
            latestRun      = allRuns.first

            let recentRuns = try store.fetchRuns(from: twelveWeeksAgo)
            readinessAssessment = predictionEngine.assess(runs: recentRuns)
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    // MARK: - HealthKit sync

    func syncHealthKit(modelContext: ModelContext) async {
        guard healthKitManager.isAvailable else { return }
        isLoadingHealthKit = true
        defer { isLoadingHealthKit = false }
        do {
            try await healthKitManager.requestAuthorization()
            let store = RunStore(modelContext: modelContext)
            let count = try await store.syncFromHealthKit()
            if count > 0 {
                load(from: modelContext)
            }
        } catch {
            errorMessage = "HealthKit sync failed: \(error.localizedDescription)"
        }
    }
}
