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
        } else {
            .health
        }
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        Group {
            if accountManager.isSignedIn {
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
                    Label("健康", systemImage: "heart.text.square.fill")
                }
                .tag(AppTab.health)

            CourseCenterView()
                .tabItem {
                    Label("学习", systemImage: "graduationcap.fill")
                }
                .tag(AppTab.learning)

            MovementCenterView()
                .tabItem {
                    Label("运动", systemImage: "figure.run.circle.fill")
                }
                .tag(AppTab.movement)

            MemberCenterView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle.fill")
                }
                .tag(AppTab.mine)
        }
    }
}

private enum AppTab: Hashable {
    case health
    case learning
    case movement
    case mine
}

#Preview {
    ContentView()
        .environmentObject(AccountManager())
        .environmentObject(HealthKitManager())
        .environmentObject(RunSessionManager())
}
