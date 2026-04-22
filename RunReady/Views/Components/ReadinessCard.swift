import SwiftUI

struct ReadinessCard: View {
    let score: RaceReadinessScore
    @Environment(UserPreferences.self) private var prefs

    var tierColor: Color {
        switch score.tier {
        case .notReady:    return .red
        case .buildBase:   return .orange
        case .nearlyReady: return Color(red: 0.9, green: 0.75, blue: 0.0)
        case .safelyReady: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(score.distance.shortLabel)
                        .font(.headline)
                    Text(UnitConversionService.formattedDistanceCompact(
                        score.distance.meters, unit: prefs.unitSystem
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Image(systemName: score.tier == .safelyReady ? "checkmark.seal.fill" : "circle.dotted")
                        .foregroundStyle(tierColor)
                        .font(.title3)
                    Text(score.tier.label)
                        .font(.caption.bold())
                        .foregroundStyle(tierColor)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(tierColor)
                        .frame(width: geo.size.width * score.progressFraction, height: 6)
                }
            }
            .frame(height: 6)

            Text(String(format: "%.0f%% readiness", score.score))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ReadinessCardExpanded: View {
    let score: RaceReadinessScore

    var tierColor: Color {
        switch score.tier {
        case .notReady:    return .red
        case .buildBase:   return .orange
        case .nearlyReady: return Color(red: 0.9, green: 0.75, blue: 0.0)
        case .safelyReady: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(score.distance.emoji + " " + score.distance.shortLabel)
                    .font(.title2.bold())
                Spacer()
                Label(score.tier.label, systemImage: score.tier.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(tierColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tierColor.opacity(0.15), in: Capsule())
            }

            // Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Readiness")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f / 100", score.score))
                        .font(.caption.bold())
                }
                ProgressView(value: score.progressFraction)
                    .tint(tierColor)
            }

            Divider()

            // Factors
            VStack(alignment: .leading, spacing: 8) {
                Text("Training Factors")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ForEach(score.factors) { factor in
                    FactorRow(factor: factor)
                }
            }

            if !score.suggestions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("To Improve")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(score.suggestions, id: \.self) { suggestion in
                        Label(suggestion, systemImage: "arrow.up.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct FactorRow: View {
    let factor: ReadinessFactor

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(factor.score >= 1.0 ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(factor.name)
                .font(.caption)
            Spacer()
            Text(String(format: "%.0f%%", factor.score * 100))
                .font(.caption.bold())
                .foregroundStyle(factor.score >= 1.0 ? .green : .orange)
        }
    }
}
