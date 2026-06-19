import SwiftUI

@main
struct XiaowuOSApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var runSessionManager = RunSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
                .environmentObject(runSessionManager)
        }
    }
}
