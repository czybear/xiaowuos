import SwiftUI

@main
struct XiaowuOSApp: App {
    @StateObject private var accountManager = AccountManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var runSessionManager = RunSessionManager()
    @StateObject private var chatService = ChatService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accountManager)
                .environmentObject(healthKitManager)
                .environmentObject(runSessionManager)
                .environmentObject(chatService)
        }
    }
}
