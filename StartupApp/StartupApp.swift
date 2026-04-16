import SwiftUI
import SwiftData

@main
struct StartupApp: App {
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
        }
        .modelContainer(for: UserProfile.self)
    }
}
