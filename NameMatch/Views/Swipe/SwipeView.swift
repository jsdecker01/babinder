import SwiftUI

struct SwipeView: View {
    @EnvironmentObject var store: AppStore
    @State private var cardStack: CardStack?
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressHeader()

                // Card stack
                if store.currentNameQueue.isEmpty {
                    EmptyStateView {
                        showFilters = true
                    }
                } else {
                    CardStack()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }

                // Action buttons
                ActionButtons()
                    .padding(.bottom, 20)
            }
            .navigationTitle(AppVersion.appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if store.canUndo {
                        Button {
                            store.undo()
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            if store.filters.activeFilterCount > 0 {
                                Text("\(store.filters.activeFilterCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FiltersView()
            }
            .overlay {
                if store.showMatchCelebration, let name = store.lastMatchedName {
                    MatchCelebrationView(name: name)
                }
            }
        }
    }
}

// MARK: - Progress Header

struct ProgressHeader: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(store.statistics.totalSwipes) swiped")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(store.remainingNames) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: progressWidth(for: geometry.size.width))
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let totalNames = store.statistics.totalSwipes + store.remainingNames
        guard totalNames > 0 else { return 0 }
        let progress = CGFloat(store.statistics.totalSwipes) / CGFloat(totalNames)
        return totalWidth * progress
    }
}

// MARK: - Action Buttons

struct ActionButtons: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack(spacing: 40) {
            // Pass button
            ActionButton(
                icon: "xmark",
                color: .red,
                size: 60
            ) {
                swipeLeft()
            }

            // Like button
            ActionButton(
                icon: "heart.fill",
                color: .green,
                size: 70
            ) {
                swipeRight()
            }
        }
        .padding(.horizontal, 40)
    }

    private func swipeLeft() {
        guard let name = store.currentNameQueue.first else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        store.swipe(name: name, liked: false)
    }

    private func swipeRight() {
        guard let name = store.currentNameQueue.first else { return }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        store.swipe(name: name, liked: true)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(color: color.opacity(0.3), radius: 8, y: 4)
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @EnvironmentObject var store: AppStore
    let onAdjustFilters: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("All caught up!")
                .font(.title2)
                .fontWeight(.bold)

            Text("You've swiped through all the names\nmatching your current filters.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if store.filters.activeFilterCount > 0 {
                Button("Adjust Filters") {
                    onAdjustFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Match Celebration

struct MatchCelebrationView: View {
    @EnvironmentObject var store: AppStore
    let name: BabyName

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration content
            VStack(spacing: 24) {
                // Hearts animation
                HStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.pink)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.pink)
                }

                Text("It's a Match!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("You and your partner both like")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))

                Text(name.name)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Button {
                    dismiss()
                } label: {
                    Text("Keep Swiping")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.pink)
                        .clipShape(Capsule())
                }
                .padding(.top, 20)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            store.dismissMatchCelebration()
        }
    }
}

#Preview {
    SwipeView()
        .environmentObject(AppStore.shared)
}
