import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var isEditing = false
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var editPhone = ""
    @State private var showSignOutAlert = false
    @State private var notificationsEnabled = true
    @State private var savedBanner = false

    private var profile: UserProfile? { profiles.first }

    var displayName: String  { profile?.name.isEmpty == false ? profile!.name : authVM.displayName }
    var displayEmail: String { profile?.email.isEmpty == false ? profile!.email : authVM.email }
    var displayPhone: String { profile?.phone ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Hero card ─────────────────────────────────────
                        VStack(spacing: 16) {
                            AvatarView(url: authVM.avatarURL, size: 96)

                            if isEditing {
                                EditableHeroFields(
                                    name: $editName,
                                    email: $editEmail,
                                    phone: $editPhone
                                )
                            } else {
                                VStack(spacing: 4) {
                                    Text(displayName)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)

                                    Text(displayEmail)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)

                                    if !displayPhone.isEmpty {
                                        Text(displayPhone)
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

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

                        // Saved banner
                        if savedBanner {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "10B981"))
                                Text("Profile saved successfully")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "10B981"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "10B981").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // ── Account ───────────────────────────────────────
                        ProfileSection(title: "Account") {
                            ProfileRow(icon: "lock.fill",       iconColor: Color(hex: "3B82F6"), title: "Security") {}
                            Divider().padding(.leading, 52)
                            ProfileRow(icon: "creditcard.fill", iconColor: Color(hex: "10B981"), title: "Billing") {}
                        }

                        // ── Preferences ───────────────────────────────────
                        ProfileSection(title: "Preferences") {
                            ToggleRow(
                                icon: "bell.fill",
                                iconColor: Color(hex: "F59E0B"),
                                title: "Notifications",
                                isOn: $notificationsEnabled
                            )
                        }

                        // ── Support ───────────────────────────────────────
                        ProfileSection(title: "Support") {
                            ProfileRow(icon: "questionmark.circle.fill", iconColor: Color(hex: "3B82F6"), title: "Help Center") {}
                            Divider().padding(.leading, 52)
                            ProfileRow(icon: "star.fill",               iconColor: Color(hex: "F59E0B"), title: "Rate the App") {}
                        }

                        // ── Sign out ──────────────────────────────────────
                        Button { showSignOutAlert = true } label: {
                            HStack {
                                Image(systemName: "arrow.right.square.fill").font(.system(size: 16))
                                Text("Sign Out").font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(hex: "EF4444").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "EF4444").opacity(0.2), lineWidth: 1))
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") { saveProfile() }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "6C63FF"))
                    } else {
                        Button("Edit") { startEditing() }
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "6C63FF"))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") { isEditing = false }
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { authVM.signOut() }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private func startEditing() {
        editName  = displayName
        editEmail = displayEmail
        editPhone = displayPhone
        isEditing = true
    }

    private func saveProfile() {
        if let existing = profile {
            existing.name      = editName.trimmingCharacters(in: .whitespaces)
            existing.email     = editEmail.trimmingCharacters(in: .whitespaces)
            existing.phone     = editPhone.trimmingCharacters(in: .whitespaces)
            existing.updatedAt = Date()
        } else {
            let newProfile = UserProfile(
                name:  editName.trimmingCharacters(in: .whitespaces),
                email: editEmail.trimmingCharacters(in: .whitespaces),
                phone: editPhone.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(newProfile)
        }
        isEditing = false
        withAnimation { savedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { savedBanner = false }
        }
    }
}

// ── Editable hero fields ──────────────────────────────────────────────────────

struct EditableHeroFields: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String

    var body: some View {
        VStack(spacing: 12) {
            EditField(icon: "person.fill",   placeholder: "Full Name",       text: $name,  keyboard: .default)
            EditField(icon: "envelope.fill", placeholder: "Email Address",   text: $email, keyboard: .emailAddress)
            EditField(icon: "phone.fill",    placeholder: "Contact Number",  text: $phone, keyboard: .phonePad)
        }
    }
}

struct EditField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let keyboard: UIKeyboardType

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6C63FF"))
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.black)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(hex: "F5F5FF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(0.3), lineWidth: 1))
    }
}

// ── Reusable components ───────────────────────────────────────────────────────

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
            VStack(spacing: 0) { content }
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
                    .foregroundColor(.black)
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
                .foregroundColor(.black)
            Spacer()
            Toggle("", isOn: $isOn).tint(iconColor).labelsHidden()
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
                startPoint: .topLeading, endPoint: .bottomTrailing
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
