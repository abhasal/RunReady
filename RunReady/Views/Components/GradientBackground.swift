import SwiftUI

struct RunReadyGradient: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.08, green: 0.08, blue: 0.20)]
                : [Color(red: 0.95, green: 0.97, blue: 1.0), .white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct SectionHeader: View {
    let title: String
    let systemImage: String?
    let actionLabel: String?
    let action: (() -> Void)?

    init(_ title: String, systemImage: String? = nil, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        HStack {
            if let img = systemImage {
                Label(title, systemImage: img)
                    .font(.headline)
            } else {
                Text(title)
                    .font(.headline)
            }
            Spacer()
            if let label = actionLabel, let action {
                Button(label, action: action)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }
}
