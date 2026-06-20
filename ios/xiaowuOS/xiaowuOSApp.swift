import SwiftUI

@main
struct XiaowuOSApp: App {
    @StateObject private var accountManager = AccountManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var runSessionManager = RunSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accountManager)
                .environmentObject(healthKitManager)
                .environmentObject(runSessionManager)
        }
    }
}
