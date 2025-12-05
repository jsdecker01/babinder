import SwiftUI

enum MatchSortOption: String, CaseIterable {
    case dateNewest = "Newest"
    case dateOldest = "Oldest"
    case ratingHigh = "Highest Rated"
    case alphabetical = "A-Z"
}

struct MatchesView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedName: BabyName?
    @State private var sortOption: MatchSortOption = .dateNewest

    var body: some View {
        NavigationStack {
            Group {
                if store.matchedNames.isEmpty {
                    EmptyMatchesView()
                } else {
                    matchesList
                }
            }
            .navigationTitle("Matches")
            .toolbar {
                if !store.matchedNames.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Sort", selection: $sortOption) {
                                ForEach(MatchSortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
            .sheet(item: $selectedName) { name in
                MatchDetailView(name: name)
            }
        }
    }

    private var sortedMatches: [(BabyName, Match)] {
        store.matchedNames.compactMap { name -> (BabyName, Match)? in
            guard let match = store.match(for: name.id) else { return nil }
            return (name, match)
        }.sorted { a, b in
            switch sortOption {
            case .dateNewest:
                return a.1.matchedAt > b.1.matchedAt
            case .dateOldest:
                return a.1.matchedAt < b.1.matchedAt
            case .ratingHigh:
                let ratingA = a.1.rating ?? 0
                let ratingB = b.1.rating ?? 0
                if ratingA == ratingB {
                    return a.1.matchedAt > b.1.matchedAt
                }
                return ratingA > ratingB
            case .alphabetical:
                return a.0.name < b.0.name
            }
        }
    }

    private var matchesList: some View {
        List {
            // Stats header
            Section {
                HStack {
                    StatBox(
                        value: "\(store.matchedNames.count)",
                        label: "Matches",
                        icon: "heart.fill",
                        color: .pink
                    )

                    StatBox(
                        value: "\(Int(store.statistics.matchRate * 100))%",
                        label: "Match Rate",
                        icon: "percent",
                        color: .purple,
                        helpText: "Percentage of names you liked that your partner also liked"
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Matched names
            Section {
                ForEach(sortedMatches, id: \.0.id) { name, match in
                    MatchRow(
                        name: name,
                        match: match,
                        isPartnerDismissed: store.partnerDismissedMatchIds.contains(name.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedName = name
                    }
                }
                .onDelete(perform: deleteMatches)
            } header: {
                Text("Your Favorites")
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteMatches(at offsets: IndexSet) {
        let sorted = sortedMatches
        for index in offsets {
            let (name, _) = sorted[index]
            store.removeMatch(nameId: name.id)
        }
    }
}

// MARK: - Match Row

struct MatchRow: View {
    let name: BabyName
    let match: Match
    var isPartnerDismissed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Gender indicator
            Circle()
                .fill(genderColor.opacity(isPartnerDismissed ? 0.1 : 0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: name.gender.icon)
                        .foregroundColor(genderColor.opacity(isPartnerDismissed ? 0.4 : 1.0))
                )

            // Name info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(name.name)
                        .font(.headline)
                        .foregroundColor(isPartnerDismissed ? .secondary : .primary)

                    // Rating display
                    if let rating = match.rating, !isPartnerDismissed {
                        HStack(spacing: 2) {
                            ForEach(1...rating, id: \.self) { _ in
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                }

                // Partner dismissed indicator
                if isPartnerDismissed {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.minus")
                            .font(.caption2)
                        Text("Partner removed")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
                // Show note indicator or meaning
                else if match.notes != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                        Text("Has notes")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } else if let meaning = name.meaning {
                    Text(meaning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Tags
                HStack(spacing: 6) {
                    if let origin = name.origins.first {
                        MiniTag(text: origin.displayName, dimmed: isPartnerDismissed)
                    }
                    if let style = name.styles.first {
                        MiniTag(text: style.displayName, dimmed: isPartnerDismissed)
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .opacity(isPartnerDismissed ? 0.7 : 1.0)
    }

    private var genderColor: Color {
        switch name.gender {
        case .male: return .blue
        case .female: return .pink
        case .neutral: return .purple
        }
    }
}

struct MiniTag: View {
    let text: String
    var dimmed: Bool = false

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(.systemGray6).opacity(dimmed ? 0.5 : 1.0))
            .clipShape(Capsule())
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var helpText: String? = nil

    @State private var showingHelp = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if helpText != nil {
                    Button {
                        showingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("About \(label)", isPresented: $showingHelp) {
            Button("Got it", role: .cancel) { }
        } message: {
            if let helpText = helpText {
                Text(helpText)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyMatchesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Matches Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("When you and your partner both\nswipe right on the same name,\nit'll appear here!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Match Detail View

struct MatchDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let name: BabyName

    @State private var notes: String = ""
    @State private var rating: Int = 0
    @FocusState private var isNotesFocused: Bool

    private var match: Match? {
        store.match(for: name.id)
    }

    private var isPartnerDismissed: Bool {
        store.partnerDismissedMatchIds.contains(name.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Partner dismissed banner
                    if isPartnerDismissed {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.minus")
                            Text("Your partner removed this from their list")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: name.gender.icon)
                            .font(.system(size: 50))
                            .foregroundColor(genderColor)

                        Text(name.name)
                            .font(.system(size: 44, weight: .bold, design: .rounded))

                        Text(name.gender.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, isPartnerDismissed ? 0 : 20)

                    // Rating
                    VStack(spacing: 8) {
                        Text("Your Rating")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { heart in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        if rating == heart {
                                            rating = 0
                                            store.updateMatchRating(nameId: name.id, rating: nil)
                                        } else {
                                            rating = heart
                                            store.updateMatchRating(nameId: name.id, rating: heart)
                                        }
                                    }
                                } label: {
                                    Image(systemName: heart <= rating ? "heart.fill" : "heart")
                                        .font(.title)
                                        .foregroundColor(heart <= rating ? .pink : .gray.opacity(0.4))
                                        .scaleEffect(heart <= rating ? 1.1 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Divider()

                    // Notes
                    DetailSection(title: "Notes") {
                        TextField("Add your thoughts...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .focused($isNotesFocused)
                            .onChange(of: notes) { _, newValue in
                                store.updateMatchNotes(nameId: name.id, notes: newValue)
                            }
                    }

                    Divider()

                    // Meaning
                    if let meaning = name.meaning {
                        DetailSection(title: "Meaning") {
                            Text(meaning)
                                .font(.body)
                        }
                    }

                    // Origins
                    if !name.origins.isEmpty {
                        DetailSection(title: "Origins") {
                            FlowLayout(spacing: 8) {
                                ForEach(name.origins) { origin in
                                    TagView(text: origin.displayName, color: .blue)
                                }
                            }
                        }
                    }

                    // Styles
                    if !name.styles.isEmpty {
                        DetailSection(title: "Styles") {
                            FlowLayout(spacing: 8) {
                                ForEach(name.styles) { style in
                                    TagView(text: style.displayName, color: .purple)
                                }
                            }
                        }
                    }

                    // Popularity
                    DetailSection(title: "Popularity") {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text(name.popularity.description)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Match date
                    if let match = match {
                        DetailSection(title: "Matched") {
                            Text(match.matchedAt.formatted(date: .long, time: .omitted))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Name Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isNotesFocused = false
                    }
                }
            }
            .onAppear {
                if let match = match {
                    rating = match.rating ?? 0
                    notes = match.notes ?? ""
                }
            }
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

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            height = y + rowHeight
        }
    }
}

#Preview {
    MatchesView()
        .environmentObject(AppStore.shared)
}
