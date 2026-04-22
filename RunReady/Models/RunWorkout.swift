import Foundation
import SwiftData

// MARK: - Enums

enum WorkoutSourceType: String, Codable {
    case manual
    case healthKit
    case liveTracked
}

// MARK: - RunWorkout

@Model
final class RunWorkout {
    var id: UUID
    var date: Date
    var duration: TimeInterval          // seconds
    var distanceMeters: Double
    var calories: Double?
    var heartRateAvgBPM: Double?
    var notes: String?
    var sourceType: WorkoutSourceType
    var healthKitWorkoutID: String?     // UUID string from HKWorkout for dedup

    @Relationship(deleteRule: .cascade)
    var routePoints: [RoutePoint]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        distanceMeters: Double,
        calories: Double? = nil,
        heartRateAvgBPM: Double? = nil,
        notes: String? = nil,
        sourceType: WorkoutSourceType = .manual,
        healthKitWorkoutID: String? = nil,
        routePoints: [RoutePoint] = []
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.calories = calories
        self.heartRateAvgBPM = heartRateAvgBPM
        self.notes = notes
        self.sourceType = sourceType
        self.healthKitWorkoutID = healthKitWorkoutID
        self.routePoints = routePoints
    }

    /// Seconds per meter — canonical pace unit; convert for display via UnitConversionService
    var averagePaceSecondsPerMeter: Double? {
        guard distanceMeters > 0 else { return nil }
        return duration / distanceMeters
    }

    /// Speed in m/s
    var averageSpeedMPS: Double {
        guard duration > 0 else { return 0 }
        return distanceMeters / duration
    }

    var hasRoute: Bool { !routePoints.isEmpty }
}
