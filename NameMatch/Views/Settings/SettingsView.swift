import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showResetAlert = false
    @State private var showHouseholdSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Statistics section
                Section {
                    StatisticsView()
                } header: {
                    Text("Your Stats")
                }

                // Household section
                Section {
                    if let household = store.household {
                        HouseholdInfoRow(household: household)

                        Button {
                            showHouseholdSheet = true
                        } label: {
                            Label("Manage Household", systemImage: "person.2")
                        }
                    } else {
                        Button {
                            showHouseholdSheet = true
                        } label: {
                            Label("Set Up Household", systemImage: "person.2.badge.plus")
                        }
                    }
                } header: {
                    Text("Household")
                } footer: {
                    Text("Share your household code with your partner to sync your swipes.")
                }

                // Data section
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will clear all your swipes, matches, and preferences. You'll stay connected to your household.")
                }

                // About section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppVersion.current.version)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink {
                        ReleaseNotesView()
                    } label: {
                        Text("Release Notes")
                    }

                    HStack {
                        Text("Total Names")
                        Spacer()
                        Text("\(NameDatabase.shared.totalCount)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink {
                        DataSourceView()
                    } label: {
                        Text("Data Sources")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                }
            } message: {
                Text("This will permanently delete all your swipes, matches, and preferences. You'll stay connected to your household, and your partner will see all matches disappear. This action cannot be undone.")
            }
            .sheet(isPresented: $showHouseholdSheet) {
                HouseholdView()
            }
        }
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 16) {
            // Main stats row
            HStack(spacing: 0) {
                StatItem(value: "\(store.statistics.totalSwipes)", label: "Total Swipes")
                Divider()
                StatItem(value: "\(store.statistics.totalLikes)", label: "Likes")
                Divider()
                StatItem(value: "\(store.statistics.matchCount)", label: "Matches")
            }
            .frame(height: 70)

            Divider()

            // Additional stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Like Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        StatHelpButton(title: "Like Rate", explanation: "Percentage of names you've swiped right on out of all your swipes")
                    }
                    Text("\(Int(store.statistics.likeRate * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Only show partner progress if household exists
                if store.household != nil {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Partner Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            StatHelpButton(title: "Partner Progress", explanation: "How many names your partner has swiped on compared to you")
                        }
                        HStack(spacing: 4) {
                            Text("\(store.statistics.partnerSwipes)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            if store.statistics.swipeDifference > 0 {
                                Text("(\(store.statistics.swipeDifference) ahead)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if store.statistics.swipeDifference < 0 {
                                Text("(\(abs(store.statistics.swipeDifference)) behind)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatHelpButton: View {
    let title: String
    let explanation: String
    @State private var showingHelp = false

    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .alert("About \(title)", isPresented: $showingHelp) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text(explanation)
        }
    }
}

// MARK: - Household Info Row

struct HouseholdInfoRow: View {
    let household: Household

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Household Code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    UIPasteboard.general.string = household.code
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            Text(household.code)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)

            HStack {
                Image(systemName: household.partnerJoined ? "checkmark.circle.fill" : "clock")
                    .foregroundColor(household.partnerJoined ? .green : .orange)
                Text(household.partnerJoined ? "Partner connected" : "Waiting for partner...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Release Notes View

struct ReleaseNotesView: View {
    var body: some View {
        List {
            ForEach(AppVersion.history.indices, id: \.self) { index in
                let version = AppVersion.history[index]
                Section {
                    Text(version.releaseNotes)
                        .font(.body)
                } header: {
                    HStack {
                        Text("Version \(version.version)")
                        Spacer()
                        Text(version.releaseDate, style: .date)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Release Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Source View

struct DataSourceView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Our name database contains \(NameDatabase.shared.totalCount) baby names from trusted, publicly available sources.")
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("We prioritize data quality and cultural sensitivity in our name selection and descriptions.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("About Our Data")
            }

            Section {
                DataSourceRow(
                    title: "U.S. Social Security Administration",
                    description: "Official 2024 baby name data from the SSA, representing the most popular names given to babies in the United States",
                    url: "https://www.ssa.gov/oact/babynames/"
                )

                DataSourceRow(
                    title: "Name Origins & Meanings",
                    description: "Etymological research from multiple linguistic and cultural sources to provide accurate name meanings and origins",
                    url: nil
                )
            } header: {
                Text("Primary Sources")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("2024 Name Database")
                        .font(.body)
                }
            } header: {
                Text("Database Info")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(AppVersion.appName) uses public domain data and respects cultural heritage. Name meanings are for informational purposes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataSourceRow: View {
    let title: String
    let description: String
    let url: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            if let url = url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("Learn more")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore.shared)
}
