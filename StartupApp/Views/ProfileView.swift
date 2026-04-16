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
    @State private var editJobRole: JobRole? = nil
    @State private var showSignOutAlert = false
    @State private var savedBanner = false

    private var profile: UserProfile? { profiles.first }

    var displayName: String    { profile?.name.isEmpty  == false ? profile!.name  : authVM.displayName }
    var displayEmail: String   { profile?.email.isEmpty == false ? profile!.email : authVM.email }
    var displayPhone: String   { profile?.phone ?? "" }
    var displayJobRole: JobRole? {
        guard let raw = profile?.jobRole, !raw.isEmpty else { return nil }
        return JobRole(rawValue: raw)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Avatar + name hero ─────────────────────────────
                        VStack(spacing: 12) {
                            AvatarView(url: authVM.avatarURL, size: 88)

                            Text(displayName)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.black)

                            HStack(spacing: 8) {
                                BadgeView(text: "Pro",      color: Color(hex: "6C63FF"))
                                BadgeView(text: "Verified", color: Color(hex: "10B981"))
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                        // ── Saved banner ───────────────────────────────────
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

                        // ── Profile info card (read or edit) ───────────────
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PROFILE INFO")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                if isEditing {
                                    // ── Edit mode ──────────────────────────
                                    VStack(spacing: 12) {
                                        EditField(icon: "person.fill",   placeholder: "Full Name",      text: $editName,  keyboard: .default)
                                        EditField(icon: "envelope.fill", placeholder: "Email Address",  text: $editEmail, keyboard: .emailAddress)
                                        EditField(icon: "phone.fill",    placeholder: "Contact Number", text: $editPhone, keyboard: .phonePad)
                                        JobRolePicker(selected: $editJobRole)
                                    }
                                    .padding(16)
                                } else {
                                    // ── Read mode ──────────────────────────
                                    InfoRow(icon: "person.fill",
                                            iconColor: Color(hex: "6C63FF"),
                                            label: "Full Name",
                                            value: displayName.isEmpty ? "Not set" : displayName,
                                            empty: displayName.isEmpty)
                                    Divider().padding(.leading, 52)

                                    InfoRow(icon: "envelope.fill",
                                            iconColor: Color(hex: "3B82F6"),
                                            label: "Email",
                                            value: displayEmail.isEmpty ? "Not set" : displayEmail,
                                            empty: displayEmail.isEmpty)
                                    Divider().padding(.leading, 52)

                                    InfoRow(icon: "phone.fill",
                                            iconColor: Color(hex: "10B981"),
                                            label: "Contact Number",
                                            value: displayPhone.isEmpty ? "Not set" : displayPhone,
                                            empty: displayPhone.isEmpty)
                                    Divider().padding(.leading, 52)

                                    HStack(spacing: 14) {
                                        Image(systemName: "briefcase.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "F59E0B"))
                                            .frame(width: 32, height: 32)
                                            .background(Color(hex: "F59E0B").opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Job Role")
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                            if let role = displayJobRole {
                                                RoleBadge(role: role)
                                            } else {
                                                Text("Not set")
                                                    .font(.system(size: 15, design: .rounded))
                                                    .foregroundColor(Color(.placeholderText))
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                            }
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        }

                        // ── Sign out ───────────────────────────────────────
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
                    Button(isEditing ? "Save" : "Edit") {
                        isEditing ? saveProfile() : startEditing()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "6C63FF"))
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
        editName    = displayName
        editEmail   = displayEmail
        editPhone   = displayPhone
        editJobRole = displayJobRole
        isEditing   = true
    }

    private func saveProfile() {
        let trimName  = editName.trimmingCharacters(in: .whitespaces)
        let trimEmail = editEmail.trimmingCharacters(in: .whitespaces)
        let trimPhone = editPhone.trimmingCharacters(in: .whitespaces)
        let roleRaw   = editJobRole?.rawValue ?? ""

        if let existing = profile {
            existing.name      = trimName
            existing.email     = trimEmail
            existing.phone     = trimPhone
            existing.jobRole   = roleRaw
            existing.updatedAt = Date()
        } else {
            modelContext.insert(UserProfile(name: trimName, email: trimEmail, phone: trimPhone, jobRole: roleRaw))
        }
        isEditing = false
        withAnimation { savedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { savedBanner = false }
        }
    }
}

// ── Info row (read mode) ───────────────────────────────────────────────────────

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var empty: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(empty ? Color(.placeholderText) : .black)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// ── Role badge ─────────────────────────────────────────────────────────────────

struct RoleBadge: View {
    let role: JobRole
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: role.icon).font(.system(size: 11, weight: .semibold))
            Text(role.rawValue).font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundColor(Color(hex: role.color))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(hex: role.color).opacity(0.12))
        .clipShape(Capsule())
    }
}

// ── Job role picker ────────────────────────────────────────────────────────────

struct JobRolePicker: View {
    @Binding var selected: JobRole?
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6C63FF"))
                        .frame(width: 20)
                    Text(selected?.rawValue ?? "Select Job Role")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(selected == nil ? Color(.placeholderText) : .black)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "6C63FF"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color(hex: "F5F5FF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(expanded ? 0.6 : 0.3), lineWidth: 1))
            }

            if expanded {
                VStack(spacing: 0) {
                    ForEach(JobRole.allCases, id: \.self) { role in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selected = role; expanded = false }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: role.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: role.color))
                                    .frame(width: 20)
                                Text(role.rawValue)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.black)
                                Spacer()
                                if selected == role {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: role.color))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(.white)
                        }
                        if role != JobRole.allCases.last {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// ── Shared components ──────────────────────────────────────────────────────────

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
