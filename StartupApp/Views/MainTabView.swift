import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house") }
                .tag(0)

            ProfileView()
                .tabItem { Label("Profile", systemImage: selectedTab == 1 ? "person.fill" : "person") }
                .tag(1)
        }
        .tint(Color(hex: "6C63FF"))
    }
}

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                VStack(spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good morning 👋")
                                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                            Text(authVM.displayName.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.black)
                        }
                        Spacer()
                        AvatarView(url: authVM.avatarURL, size: 48)
                    }
                    .padding(20).background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

                    HStack(spacing: 14) {
                        StatCard(value: "12",   label: "Applied",  icon: "paperplane.fill",       color: Color(hex: "6C63FF"))
                        StatCard(value: "4",    label: "Replies",  icon: "envelope.fill",          color: Color(hex: "10B981"))
                        StatCard(value: "98%",  label: "Match",    icon: "checkmark.seal.fill",    color: Color(hex: "F59E0B"))
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("").navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.black)
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18)).shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
