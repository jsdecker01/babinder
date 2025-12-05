import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab = 0
    @State private var hasSetInitialTab = false

    var body: some View {
        TabView(selection: $selectedTab) {
            SwipeView()
                .tabItem {
                    Label("Swipe", systemImage: "rectangle.stack")
                }
                .tag(0)

            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
                .badge(store.matchedNames.count > 0 ? store.matchedNames.count : 0)
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .onAppear {
            // If household exists and this is first appearance, show settings tab
            // (user just created household during onboarding)
            if !hasSetInitialTab {
                if store.household != nil {
                    selectedTab = 2  // Settings tab
                }
                hasSetInitialTab = true
            }

            // Ensure name queue is loaded
            if store.currentNameQueue.isEmpty {
                store.loadNameQueue()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStore.shared)
}
