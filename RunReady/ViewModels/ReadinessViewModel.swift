import Foundation
import SwiftData
import Observation

@Observable
final class ReadinessViewModel {

    var assessment: ReadinessAssessment = .empty
    var isLoading: Bool = false

    private let engine: PredictionEngine

    init(engine: PredictionEngine = PredictionEngine()) {
        self.engine = engine
    }

    func refresh(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }
        let twelveWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date())!
        do {
            let store = RunStore(modelContext: modelContext)
            let runs = try store.fetchRuns(from: twelveWeeksAgo)
            assessment = engine.assess(runs: runs)
        } catch {
            print("[ReadinessViewModel] fetch error: \(error)")
        }
    }
}
