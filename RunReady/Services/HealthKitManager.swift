import Foundation
import HealthKit

// MARK: - Authorization status for UI

enum HKAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

// MARK: - HealthKitManager

/// Manages all HealthKit interactions. Designed to be injected as a singleton.
/// All async methods throw on failure so call sites can handle gracefully.
@Observable
final class HealthKitManager {

    // TODO: HealthKit requires the "HealthKit" capability in your Xcode target and
    //       NSHealthShareUsageDescription / NSHealthUpdateUsageDescription in Info.plist.

    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Types to read

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let cal = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(cal) }
        if let dist = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(dist) }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isAvailable else {
            authorizationStatus = .unavailable
            return
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        await updateAuthStatus()
    }

    @MainActor
    private func updateAuthStatus() {
        let workoutType = HKObjectType.workoutType()
        let status = store.authorizationStatus(for: workoutType)
        switch status {
        case .sharingAuthorized:  authorizationStatus = .authorized
        case .sharingDenied:      authorizationStatus = .denied
        case .notDetermined:      authorizationStatus = .notDetermined
        @unknown default:         authorizationStatus = .notDetermined
        }
    }

    // MARK: - Fetch running workouts

    func fetchRunningWorkouts(from startDate: Date, to endDate: Date = Date()) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, workoutPredicate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: compound,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }

    // MARK: - Convert HKWorkout → RunWorkout

    func convertToRunWorkout(_ hkWorkout: HKWorkout) -> RunWorkout {
        RunWorkout(
            date: hkWorkout.startDate,
            duration: hkWorkout.duration,
            distanceMeters: hkWorkout.totalDistance?.doubleValue(for: .meter()) ?? 0,
            calories: hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
            sourceType: .healthKit,
            healthKitWorkoutID: hkWorkout.uuid.uuidString
        )
    }

    // MARK: - Fetch heart rate for a workout

    func fetchAverageHeartRate(for workout: HKWorkout) async throws -> Double? {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let avg = stats?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: avg)
            }
            store.execute(query)
        }
    }

    // MARK: - Fetch route points for a workout

    func fetchRoutePoints(for workout: HKWorkout) async throws -> [RoutePoint] {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let routes: [HKWorkoutRoute] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }
            store.execute(query)
        }

        guard let route = routes.first else { return [] }

        var points: [RoutePoint] = []
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error { continuation.resume(throwing: error); return }
                if let locations {
                    points.append(contentsOf: locations.map { RoutePoint.from($0) })
                }
                if done {
                    continuation.resume(returning: points)
                }
            }
            self.store.execute(query)
        }
    }
}
