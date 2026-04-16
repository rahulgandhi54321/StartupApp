import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSignOutAlert = false
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile hero card
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(url: authVM.avatarURL, size: 96)

                                Circle()
                                    .fill(Color(hex: "6C63FF"))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 4, y: 4)
                            }

                            VStack(spacing: 4) {
                                Text(authVM.displayName)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text(authVM.email)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            // Badges
                            HStack(spacing: 8) {
                                BadgeView(text: "Pro", color: Color(hex: "6C63FF"))
                                BadgeView(text: "Verified", color: Color(hex: "10B981"))
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                        // Account section
                        ProfileSection(title: "Account") {
                            ProfileRow(icon: "person.fill", iconColor: Color(hex: "6C63FF"), title: "Edit Profile") {}
                            Divider().padding(.leading, 52)
                            ProfileRow(icon: "lock.fill", iconColor: Color(hex: "3B82F6"), title: "Security") {}
                            Divider().padding(.leading, 52)
                            ProfileRow(icon: "creditcard.fill", iconColor: Color(hex: "10B981"), title: "Billing") {}
                        }

                        // Preferences section
                        ProfileSection(title: "Preferences") {
                            ToggleRow(
                                icon: "bell.fill",
                                iconColor: Color(hex: "F59E0B"),
                                title: "Notifications",
                                isOn: $notificationsEnabled
                            )
                            Divider().padding(.leading, 52)
                            ToggleRow(
                                icon: "moon.fill",
                                iconColor: Color(hex: "6C63FF"),
                                title: "Dark Mode",
                                isOn: $darkModeEnabled
                            )
                        }

                        // Support section
                        ProfileSection(title: "Support") {
                            ProfileRow(icon: "questionmark.circle.fill", iconColor: Color(hex: "3B82F6"), title: "Help Center") {}
                            Divider().padding(.leading, 52)
                            ProfileRow(icon: "envelope.fill", iconColor: Color(hex: "10B981"), title: "Contact Us") {}
                            Divider().padding(.leading, 52)
                            ProfileRow(icon: "star.fill", iconColor: Color(hex: "F59E0B"), title: "Rate the App") {}
                        }

                        // Sign out
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "EF4444").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "EF4444").opacity(0.2), lineWidth: 1)
                            )
                        }

                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { authVM.signOut() }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(iconColor)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AvatarView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            LinearGradient(
                colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundColor(.white)
            )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}
