import SwiftUI

struct NameCard: View {
    let name: BabyName
    let isTopCard: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Gender icon with subtle glow
                ZStack {
                    Circle()
                        .fill(genderColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: name.gender.icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(genderColor)
                }
                .padding(.bottom, 20)

                // Name
                Text(name.name)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 16)

                // Meaning
                if let meaning = name.meaning {
                    Text(meaning)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                    .frame(minHeight: 24)

                // Tags
                VStack(spacing: 16) {
                    // Origin tags
                    if !name.origins.isEmpty {
                        VStack(spacing: 8) {
                            Text("Origin")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            HStack(spacing: 8) {
                                ForEach(name.origins.prefix(3)) { origin in
                                    TagView(text: origin.displayName, color: .blue)
                                }
                            }
                        }
                    }

                    // Style tags
                    if !name.styles.isEmpty {
                        VStack(spacing: 8) {
                            Text("Style")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            HStack(spacing: 8) {
                                ForEach(name.styles.prefix(3)) { style in
                                    TagView(text: style.displayName, color: .purple)
                                }
                            }
                        }
                    }

                    // Popularity
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                        Text(name.popularity.description)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }

                Spacer()
                    .frame(height: 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .shadow(color: genderColor.opacity(0.15), radius: isTopCard ? 20 : 8, y: isTopCard ? 8 : 4)
                .shadow(color: .black.opacity(0.1), radius: isTopCard ? 8 : 4, y: isTopCard ? 4 : 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                colorScheme == .dark ? Color(.systemGray6) : .white,
                colorScheme == .dark ? Color(.systemGray5) : Color(white: 0.97),
                genderAccentColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var genderAccentColor: Color {
        switch name.gender {
        case .male: return colorScheme == .dark ? Color(red: 0.15, green: 0.2, blue: 0.3) : Color(red: 0.9, green: 0.93, blue: 1.0)
        case .female: return colorScheme == .dark ? Color(red: 0.3, green: 0.15, blue: 0.2) : Color(red: 1.0, green: 0.92, blue: 0.95)
        case .neutral: return colorScheme == .dark ? Color(red: 0.25, green: 0.15, blue: 0.3) : Color(red: 0.96, green: 0.92, blue: 1.0)
        }
    }

    private var genderColor: Color {
        switch name.gender {
        case .male: return .blue
        case .female: return .pink
        case .neutral: return .purple
        }
    }
}

struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

#Preview {
    NameCard(
        name: BabyName(
            name: "Oliver",
            gender: .male,
            origins: [.english, .latin],
            styles: [.classic, .literary],
            meaning: "Olive tree, symbol of peace",
            popularity: .popular
        ),
        isTopCard: true
    )
    .padding()
    .frame(height: 500)
}
