import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home",    systemImage: selectedTab == 0 ? "house.fill"      : "house") }
                .tag(0)

            JobFeedView()
                .tabItem { Label("Jobs",    systemImage: selectedTab == 1 ? "briefcase.fill"  : "briefcase") }
                .tag(1)

            JobPortalsView()
                .tabItem { Label("Portals", systemImage: selectedTab == 2 ? "globe.badge.chevron.backward" : "globe") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: selectedTab == 3 ? "person.fill"     : "person") }
                .tag(3)
        }
        .tint(Color(hex: "6C63FF"))
        .task { await authVM.loadUserData() }
    }
}
