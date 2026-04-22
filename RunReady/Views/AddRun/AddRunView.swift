import SwiftUI
import SwiftData

struct AddRunView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(UserPreferences.self) private var prefs

    // Form fields
    @State private var date: Date = Date()
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 30
    @State private var durationSeconds: Int = 0
    @State private var distanceText: String = ""
    @State private var notes: String = ""
    @State private var caloriesText: String = ""
    @State private var showValidationError = false
    @State private var validationMessage = ""

    private var totalDurationSeconds: TimeInterval {
        TimeInterval(durationHours * 3600 + durationMinutes * 60 + durationSeconds)
    }

    private var distanceInMeters: Double? {
        guard let value = Double(distanceText), value > 0 else { return nil }
        return prefs.unitSystem == .metric
            ? UnitConversionService.kilometersToMeters(value)
            : UnitConversionService.milesToMeters(value)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Date & Time
                Section("When") {
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                // Duration
                Section("Duration") {
                    HStack(spacing: 0) {
                        pickerColumn(value: $durationHours, range: 0...23, label: "h")
                        pickerColumn(value: $durationMinutes, range: 0...59, label: "m")
                        pickerColumn(value: $durationSeconds, range: 0...59, label: "s")
                    }
                    .frame(height: 120)
                }

                // Distance
                Section("Distance (\(prefs.unitSystem.distanceUnit))") {
                    TextField("e.g. 5.0", text: $distanceText)
                        .keyboardType(.decimalPad)
                }

                // Optional extras
                Section("Optional") {
                    TextField("Calories burned", text: $caloriesText)
                        .keyboardType(.numberPad)
                    TextField("Notes (how did it feel?)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log a Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRun() }
                        .bold()
                }
            }
            .alert("Check your entry", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Picker helper

    private func pickerColumn(value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        Picker("", selection: value) {
            ForEach(range, id: \.self) { n in
                Text("\(n)\(label)").tag(n)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // MARK: - Save

    private func saveRun() {
        guard totalDurationSeconds > 0 else {
            validationMessage = "Duration must be at least 1 minute."
            showValidationError = true
            return
        }
        guard let meters = distanceInMeters else {
            validationMessage = "Please enter a valid distance."
            showValidationError = true
            return
        }

        let calories = Double(caloriesText)
        let run = RunWorkout(
            date: date,
            duration: totalDurationSeconds,
            distanceMeters: meters,
            calories: calories,
            notes: notes.isEmpty ? nil : notes,
            sourceType: .manual
        )

        do {
            let store = RunStore(modelContext: modelContext)
            try store.save(run)
            dismiss()
        } catch {
            validationMessage = "Failed to save: \(error.localizedDescription)"
            showValidationError = true
        }
    }
}

#Preview {
    AddRunView()
        .environment(UserPreferences())
        .modelContainer(PreviewData.container)
}
