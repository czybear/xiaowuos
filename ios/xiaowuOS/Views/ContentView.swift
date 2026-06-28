import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var accountManager: AccountManager
    @State private var selectedTab: AppTab

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: AppTab = if arguments.contains("-showRunTab") {
            .movement
        } else if arguments.contains("-showMemberTab") {
            .mine
        } else if arguments.contains("-showCourseTab") {
            .learning
        } else if arguments.contains("-showExploreTab") {
            .explore
        } else {
            .health
        }
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        Group {
            if ProcessInfo.processInfo.arguments.contains("-showRacingGame") {
                NavigationStack {
                    RacingGameView()
                }
            } else if accountManager.isSignedIn {
                signedInTabs
            } else {
                MemberCenterView()
            }
        }
        .tint(.orange)
    }

    private var signedInTabs: some View {
        TabView(selection: $selectedTab) {
            HealthDashboardView()
                .tabItem {
                    Label("健康", systemImage: "heart.fill")
                }
                .tag(AppTab.health)

            MovementCenterView()
                .tabItem {
                    Label("运动", systemImage: "arrow.up.right")
                }
                .tag(AppTab.movement)

            CourseCenterView()
                .tabItem {
                    Label("学习", systemImage: "book.fill")
                }
                .tag(AppTab.learning)

            ExploreCenterView()
                .tabItem {
                    Label("探索", systemImage: "sparkles")
                }
                .tag(AppTab.explore)

            MemberCenterView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(AppTab.mine)
        }
    }
}

private enum AppTab: Hashable {
    case health
    case learning
    case movement
    case explore
    case mine
}

#Preview {
    ContentView()
        .environmentObject(AccountManager())
        .environmentObject(HealthKitManager())
        .environmentObject(RunSessionManager())
        .environmentObject(ChatService())
}
