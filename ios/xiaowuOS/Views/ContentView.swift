import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab

    init() {
        let initialTab: AppTab = ProcessInfo.processInfo.arguments.contains("-showRunTab") ? .run : .health
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HealthDashboardView()
                .tabItem {
                    Label("健康", systemImage: "heart.text.square.fill")
                }
                .tag(AppTab.health)

            RunCompanionView()
                .tabItem {
                    Label("跑步", systemImage: "figure.run.circle.fill")
                }
                .tag(AppTab.run)
        }
        .tint(.orange)
    }
}

private enum AppTab: Hashable {
    case health
    case run
}

#Preview {
    ContentView()
        .environmentObject(HealthKitManager())
        .environmentObject(RunSessionManager())
}
