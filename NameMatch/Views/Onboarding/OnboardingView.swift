import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var currentPage = 0
    @State private var joinCode = ""
    @State private var isJoining = false
    @State private var showError = false

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentColor : Color(.systemGray4))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                }
            }
            .padding(.top, 20)
            .animation(.spring(response: 0.3), value: currentPage)

            // Page content
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)

                HowItWorksPage()
                    .tag(1)

                FeaturesPage()
                    .tag(2)

                SetupPage(
                    joinCode: $joinCode,
                    isJoining: $isJoining,
                    showError: $showError,
                    onCreateHousehold: createHousehold,
                    onJoinHousehold: joinHousehold
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                if currentPage < totalPages - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Could not join household. Please check the code and try again.")
        }
    }

    private func createHousehold() {
        store.createHousehold()
        store.completeOnboarding()
    }

    private func joinHousehold() {
        isJoining = true
        Task {
            let success = await store.joinHousehold(code: joinCode)
            await MainActor.run {
                isJoining = false
                if success {
                    store.completeOnboarding()
                } else {
                    showError = true
                }
            }
        }
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon placeholder
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text(AppVersion.appName)
                    .font(.system(size: 44, weight: .bold, design: .rounded))

                Text("Find the perfect baby name together")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - How It Works Page

struct HowItWorksPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How It Works")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 24) {
                OnboardingStep(
                    number: 1,
                    icon: "hand.draw",
                    title: "Swipe Through Names",
                    description: "Like Tinder, but for baby names. Swipe right to like, left to pass."
                )

                OnboardingStep(
                    number: 2,
                    icon: "person.2",
                    title: "Sync With Your Partner",
                    description: "Connect with your partner using a shared code."
                )

                OnboardingStep(
                    number: 3,
                    icon: "heart.fill",
                    title: "Match on Favorites",
                    description: "When you both swipe right on the same name - it's a match!"
                )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct OnboardingStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Features Page

struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Features")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                FeatureRow(
                    icon: "slider.horizontal.3",
                    title: "Smart Filters",
                    description: "Filter by gender, origin, style, popularity"
                )

                FeatureRow(
                    icon: "icloud",
                    title: "Cloud Sync",
                    description: "Automatic sync across all your devices"
                )

                FeatureRow(
                    icon: "arrow.uturn.backward",
                    title: "Undo Swipes",
                    description: "Made a mistake? Undo your last 5 swipes"
                )

                FeatureRow(
                    icon: "chart.bar",
                    title: "Statistics",
                    description: "Track your progress and match rate"
                )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Setup Page

struct SetupPage: View {
    @Binding var joinCode: String
    @Binding var isJoining: Bool
    @Binding var showError: Bool
    let onCreateHousehold: () -> Void
    let onJoinHousehold: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Get Started")
                .font(.title)
                .fontWeight(.bold)

            Text("Are you starting fresh or joining your partner?")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Create new household
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                Text("Create New Household")
                    .font(.headline)

                Text("Generate a code to share with your partner")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    onCreateHousehold()
                } label: {
                    Text("Create Household")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Divider
            HStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                Text("or")
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
            }

            // Join existing household
            VStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)

                Text("Join Partner's Household")
                    .font(.headline)

                TextField("Enter 6-digit code", text: $joinCode)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = String(newValue.uppercased().prefix(6))
                    }

                Button {
                    onJoinHousehold()
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
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStore.shared)
}
