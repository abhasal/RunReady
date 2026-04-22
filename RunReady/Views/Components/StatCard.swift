import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    var accentColor: Color = .blue

    init(title: String, value: String, subtitle: String? = nil, icon: String, accentColor: Color = .blue) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct StatCardGrid: View {
    @Environment(UserPreferences.self) private var prefs
    let today: Double
    let week: Double
    let month: Double
    let year: Double

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Today",
                value: UnitConversionService.formattedDistanceCompact(today, unit: prefs.unitSystem),
                icon: "calendar",
                accentColor: .orange
            )
            StatCard(
                title: "This Week",
                value: UnitConversionService.formattedDistanceCompact(week, unit: prefs.unitSystem),
                icon: "calendar.badge.clock",
                accentColor: .blue
            )
            StatCard(
                title: "This Month",
                value: UnitConversionService.formattedDistanceCompact(month, unit: prefs.unitSystem),
                icon: "calendar.badge.plus",
                accentColor: .purple
            )
            StatCard(
                title: "This Year",
                value: UnitConversionService.formattedDistanceCompact(year, unit: prefs.unitSystem),
                icon: "trophy",
                accentColor: .yellow
            )
        }
    }
}

#Preview {
    StatCardGrid(today: 5000, week: 28000, month: 110000, year: 480000)
        .environment(UserPreferences())
        .padding()
}
