import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    // Separate state for each filter to avoid binding issues with NavigationLink
    @State private var selectedGenders: Set<Gender> = Set(Gender.allCases)
    @State private var selectedPopularities: Set<Popularity> = Set(Popularity.allCases)
    @State private var selectedOrigins: Set<Origin> = []
    @State private var selectedStyles: Set<Style> = []
    @State private var selectedLetters: Set<String> = []
    @State private var hasLoadedFromStore = false

    var body: some View {
        NavigationStack {
            Form {
                // Gender section
                Section {
                    ForEach(Gender.allCases) { gender in
                        FilterToggleRow(
                            title: gender.displayName,
                            icon: gender.icon,
                            isSelected: selectedGenders.contains(gender)
                        ) {
                            toggleGender(gender)
                        }
                    }
                } header: {
                    Text("Gender")
                } footer: {
                    Text("Select which genders to include in your swipe queue.")
                }

                // Popularity section
                Section {
                    ForEach(Popularity.allCases) { popularity in
                        FilterToggleRow(
                            title: popularity.displayName,
                            subtitle: popularity.description,
                            isSelected: selectedPopularities.contains(popularity)
                        ) {
                            togglePopularity(popularity)
                        }
                    }
                } header: {
                    Text("Popularity")
                }

                // Origins section
                Section {
                    NavigationLink {
                        OriginFilterView(selectedOrigins: $selectedOrigins)
                    } label: {
                        HStack {
                            Text("Origins")
                            Spacer()
                            if selectedOrigins.isEmpty {
                                Text("All")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(selectedOrigins.count) selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Origin")
                } footer: {
                    Text("Filter by name origin or cultural background.")
                }

                // Styles section
                Section {
                    NavigationLink {
                        StyleFilterView(selectedStyles: $selectedStyles)
                    } label: {
                        HStack {
                            Text("Styles")
                            Spacer()
                            if selectedStyles.isEmpty {
                                Text("All")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(selectedStyles.count) selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Style")
                } footer: {
                    Text("Filter by name style or character.")
                }

                // First letter section
                Section {
                    NavigationLink {
                        LetterFilterView(selectedLetters: $selectedLetters)
                    } label: {
                        HStack {
                            Text("First Letter")
                            Spacer()
                            if selectedLetters.isEmpty {
                                Text("All")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(selectedLetters.sorted().joined(separator: ", "))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                } header: {
                    Text("Starts With")
                }

                // Reset section
                if !isDefault {
                    Section {
                        Button("Reset All Filters") {
                            resetToDefaults()
                        }
                        .foregroundColor(.red)
                    }
                }

                // Preview count
                Section {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.accentColor)
                        Text("Names matching filters")
                        Spacer()
                        Text("\(matchingCount)")
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                }

                // Apply button
                Section {
                    Button {
                        applyFilters()
                    } label: {
                        Text("Apply Filters")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if !hasLoadedFromStore {
                    loadFromStore()
                    hasLoadedFromStore = true
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var currentFilters: NameFilters {
        NameFilters(
            genders: selectedGenders,
            origins: selectedOrigins,
            styles: selectedStyles,
            firstLetters: selectedLetters,
            popularities: selectedPopularities
        )
    }

    private var matchingCount: Int {
        NameDatabase.shared.filteredNames(with: currentFilters, excluding: store.swipedNameIds).count
    }

    private var isDefault: Bool {
        selectedGenders == Set(Gender.allCases) &&
        selectedOrigins.isEmpty &&
        selectedStyles.isEmpty &&
        selectedLetters.isEmpty &&
        selectedPopularities == Set(Popularity.allCases)
    }

    // MARK: - Actions

    private func loadFromStore() {
        selectedGenders = store.filters.genders
        selectedPopularities = store.filters.popularities
        selectedOrigins = store.filters.origins
        selectedStyles = store.filters.styles
        selectedLetters = store.filters.firstLetters
    }

    private func applyFilters() {
        let newFilters = currentFilters
        print("Applying filters - letters: \(newFilters.firstLetters)")
        store.updateFilters(newFilters)
        dismiss()
    }

    private func resetToDefaults() {
        selectedGenders = Set(Gender.allCases)
        selectedPopularities = Set(Popularity.allCases)
        selectedOrigins = []
        selectedStyles = []
        selectedLetters = []
    }

    private func toggleGender(_ gender: Gender) {
        if selectedGenders.contains(gender) {
            if selectedGenders.count > 1 {
                selectedGenders.remove(gender)
            }
        } else {
            selectedGenders.insert(gender)
        }
    }

    private func togglePopularity(_ popularity: Popularity) {
        if selectedPopularities.contains(popularity) {
            if selectedPopularities.count > 1 {
                selectedPopularities.remove(popularity)
            }
        } else {
            selectedPopularities.insert(popularity)
        }
    }
}

// MARK: - Filter Toggle Row

struct FilterToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Origin Filter View

struct OriginFilterView: View {
    @Binding var selectedOrigins: Set<Origin>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button("Select All") {
                    selectedOrigins = Set(Origin.allCases)
                }

                Button("Clear All") {
                    selectedOrigins.removeAll()
                }
            }

            Section {
                ForEach(Origin.allCases) { origin in
                    FilterToggleRow(
                        title: origin.displayName,
                        subtitle: "\(NameDatabase.shared.count(for: origin)) names",
                        isSelected: selectedOrigins.contains(origin)
                    ) {
                        if selectedOrigins.contains(origin) {
                            selectedOrigins.remove(origin)
                        } else {
                            selectedOrigins.insert(origin)
                        }
                    }
                }
            }
        }
        .navigationTitle("Origins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Style Filter View

struct StyleFilterView: View {
    @Binding var selectedStyles: Set<Style>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button("Select All") {
                    selectedStyles = Set(Style.allCases)
                }

                Button("Clear All") {
                    selectedStyles.removeAll()
                }
            }

            Section {
                ForEach(Style.allCases) { style in
                    FilterToggleRow(
                        title: style.displayName,
                        subtitle: "\(NameDatabase.shared.count(for: style)) names",
                        isSelected: selectedStyles.contains(style)
                    ) {
                        if selectedStyles.contains(style) {
                            selectedStyles.remove(style)
                        } else {
                            selectedStyles.insert(style)
                        }
                    }
                }
            }
        }
        .navigationTitle("Styles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Letter Filter View

struct LetterFilterView: View {
    @Binding var selectedLetters: Set<String>

    private let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    private let columns = [
        GridItem(.adaptive(minimum: 50), spacing: 10)
    ]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Quick actions
                HStack {
                    Button("Select All") {
                        selectedLetters = Set(letters)
                    }
                    .buttonStyle(.bordered)

                    Button("Clear All") {
                        selectedLetters.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                // Selected indicator
                if !selectedLetters.isEmpty {
                    Text("Selected: \(selectedLetters.sorted().joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal)
                }

                // Letter grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(letters, id: \.self) { letter in
                        LetterButton(
                            letter: letter,
                            isSelected: selectedLetters.contains(letter)
                        ) {
                            if selectedLetters.contains(letter) {
                                selectedLetters.remove(letter)
                            } else {
                                selectedLetters.insert(letter)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("First Letter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct LetterButton: View {
    let letter: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FiltersView()
        .environmentObject(AppStore.shared)
}
