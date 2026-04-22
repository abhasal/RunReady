import Foundation
import SwiftData
import Observation

@Observable
final class SettingsViewModel {

    var syncMessage: String?
    var isSyncing: Bool = false

    func syncHealthKit(modelContext: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await HealthKitManager.shared.requestAuthorization()
            let store = RunStore(modelContext: modelContext)
            let count = try await store.syncFromHealthKit(weeks: 52)
            syncMessage = "Imported \(count) new run(s) from Apple Health."
        } catch {
            syncMessage = "Sync failed: \(error.localizedDescription)"
        }
    }

    func deleteAllRuns(modelContext: ModelContext) throws {
        let store = RunStore(modelContext: modelContext)
        let all = try store.fetchAll()
        for run in all {
            try store.delete(run)
        }
        syncMessage = "All runs deleted."
    }
}
