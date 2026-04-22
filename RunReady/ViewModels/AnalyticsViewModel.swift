import Foundation
import SwiftData
import Observation

struct WeeklyDataPoint: Identifiable {
    let id: UUID = UUID()
    let weekStart: Date
    let totalMeters: Double
    let runCount: Int

    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

struct MonthlyStats: Identifiable {
    let id = UUID()
    let month: Date
    let totalMeters: Double
    let runCount: Int
    let longestRunMeters: Double
    let avgPaceSecondsPerMeter: Double?

    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }
}

@Observable
final class AnalyticsViewModel {

    var weeklyData: [WeeklyDataPoint] = []
    var monthlyStats: [MonthlyStats] = []
    var personalRecord: RunWorkout?
    var longestStreak: Int = 0
    var totalLifetimeMeters: Double = 0
    var totalLifetimeRuns: Int = 0
    var errorMessage: String?

    func load(modelContext: ModelContext) {
        do {
            let store = RunStore(modelContext: modelContext)
            let allRuns = try store.fetchAll()
            totalLifetimeRuns = allRuns.count
            totalLifetimeMeters = allRuns.reduce(0) { $0 + $1.distanceMeters }
            personalRecord = allRuns.max(by: { $0.distanceMeters < $1.distanceMeters })
            longestStreak = computeLongestStreak(runs: allRuns)
            weeklyData = buildWeeklyData(runs: allRuns, weeks: 12)
            monthlyStats = buildMonthlyStats(runs: allRuns, months: 6)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private builders

    private func buildWeeklyData(runs: [RunWorkout], weeks: Int) -> [WeeklyDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var result: [WeeklyDataPoint] = []
        for i in stride(from: weeks - 1, through: 0, by: -1) {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: startOfWeek(for: now))!
            let weekEnd   = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let weekRuns  = runs.filter { $0.date >= weekStart && $0.date < weekEnd }
            result.append(WeeklyDataPoint(
                weekStart: weekStart,
                totalMeters: weekRuns.reduce(0) { $0 + $1.distanceMeters },
                runCount: weekRuns.count
            ))
        }
        return result
    }

    private func buildMonthlyStats(runs: [RunWorkout], months: Int) -> [MonthlyStats] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyStats] = []
        for i in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: startOfMonth(for: now)) else { continue }
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            let monthRuns = runs.filter { $0.date >= monthStart && $0.date < monthEnd }
            let avgPace: Double?
            let totalDist = monthRuns.reduce(0.0) { $0 + $1.distanceMeters }
            let totalDur  = monthRuns.reduce(0.0) { $0 + $1.duration }
            if totalDist > 0 { avgPace = totalDur / totalDist } else { avgPace = nil }
            result.append(MonthlyStats(
                month: monthStart,
                totalMeters: totalDist,
                runCount: monthRuns.count,
                longestRunMeters: monthRuns.map(\.distanceMeters).max() ?? 0,
                avgPaceSecondsPerMeter: avgPace
            ))
        }
        return result
    }

    private func computeLongestStreak(runs: [RunWorkout]) -> Int {
        guard !runs.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sortedDays = Set(runs.map { calendar.startOfDay(for: $0.date) }).sorted()
        var maxStreak = 1, current = 1
        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
            if diff == 1 { current += 1; maxStreak = max(maxStreak, current) }
            else { current = 1 }
        }
        return maxStreak
    }

    private func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }

    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
}
