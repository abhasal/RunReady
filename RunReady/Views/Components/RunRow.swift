import SwiftUI

struct RunRow: View {
    let run: RunWorkout
    @Environment(UserPreferences.self) private var prefs

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(dateString)
                    .font(.subheadline.bold())
                Text(run.notes ?? "Running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(UnitConversionService.formattedDistanceCompact(run.distanceMeters, unit: prefs.unitSystem))
                    .font(.subheadline.bold())
                if let pace = run.averagePaceSecondsPerMeter {
                    Text(UnitConversionService.formattedPace(secondsPerMeter: pace, unit: prefs.unitSystem))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: run.date)
    }

    private var iconName: String {
        switch run.sourceType {
        case .healthKit:    return "heart.fill"
        case .liveTracked:  return "figure.run"
        case .manual:       return "pencil"
        }
    }

    private var iconColor: Color {
        switch run.sourceType {
        case .healthKit:    return .red
        case .liveTracked:  return .blue
        case .manual:       return .green
        }
    }
}
