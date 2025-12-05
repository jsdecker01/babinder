import SwiftUI

@main
struct NameMatchApp: App {
    @StateObject private var store = AppStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if store.needsOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}
