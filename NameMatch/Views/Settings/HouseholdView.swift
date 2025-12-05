import SwiftUI

struct HouseholdView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    @State private var joinCode = ""
    @State private var isJoining = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLeaveConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if let household = store.household {
                    existingHouseholdView(household: household)
                } else {
                    newHouseholdView
                }
            }
            .padding()
            .navigationTitle("Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Existing Household View

    @ViewBuilder
    private func existingHouseholdView(household: Household) -> some View {
        VStack(spacing: 24) {
            // Status icon
            Image(systemName: household.partnerJoined ? "person.2.circle.fill" : "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(household.partnerJoined ? .green : .accentColor)

            // Status text
            VStack(spacing: 8) {
                Text(household.partnerJoined ? "Connected!" : "Waiting for Partner")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(household.partnerJoined
                    ? "You and your partner are synced. Happy swiping!"
                    : "Share your code with your partner to start matching.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Code display
            VStack(spacing: 12) {
                Text("Your Household Code")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(household.code)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .tracking(4)

                Button {
                    UIPasteboard.general.string = household.code
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Share button
            ShareLink(item: "Join my \(AppVersion.appName) household with code: \(household.code)") {
                Label("Share Code", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            // Sync button
            Button {
                Task {
                    await store.syncWithCloud()
                }
            } label: {
                if store.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(store.isSyncing)

            // Sync status
            if let error = store.lastSyncError {
                Text("Sync error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Partner swipes count
            if store.partnerSwipes.count > 0 {
                Text("Partner has swiped on \(store.partnerSwipes.count) names")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Leave household button
            Button(role: .destructive) {
                showLeaveConfirmation = true
            } label: {
                Label("Leave Household", systemImage: "person.badge.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .confirmationDialog(
                "Leave Household?",
                isPresented: $showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leave Household", role: .destructive) {
                    store.leaveHousehold()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will disconnect you from your current household. Your swipes and matches will be preserved.")
            }
        }
    }

    // MARK: - New Household View

    private var newHouseholdView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text("Set Up Household")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create a new household and share the code with your partner. You'll both use the same code.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Create new
            VStack(spacing: 12) {
                Text("Start New Household")
                    .font(.headline)

                Button {
                    store.createHousehold()
                } label: {
                    Text("Create Household")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            // Or divider
            HStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
            }

            // Join existing
            VStack(spacing: 12) {
                Text("Join Partner's Household")
                    .font(.headline)

                TextField("Enter 6-digit code", text: $joinCode)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.title3, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = String(newValue.uppercased().prefix(6))
                    }

                Button {
                    joinHousehold()
                } label: {
                    if isJoining {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Join Household")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(joinCode.count != 6 || isJoining)
            }

            Spacer()
        }
    }

    private func joinHousehold() {
        isJoining = true

        Task {
            let success = await store.joinHousehold(code: joinCode)

            await MainActor.run {
                isJoining = false

                if !success {
                    errorMessage = "Could not find a household with that code. Please check and try again."
                    showError = true
                }
            }
        }
    }
}

#Preview {
    HouseholdView()
        .environmentObject(AppStore.shared)
}
