import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var isEditing   = false
    @State private var editName    = ""
    @State private var editEmail   = ""
    @State private var editPhone   = ""
    @State private var editJobRole: JobRole? = nil
    @State private var editGender: Gender?   = nil

    @State private var isLoading   = false
    @State private var isSaving    = false
    @State private var savedBanner = false
    @State private var errorMsg: String?

    var p: SupabaseService.ProfileRow? { authVM.remoteProfile }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading…").tint(Color(hex: "6C63FF"))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            // ── Avatar hero ────────────────────────────────
                            VStack(spacing: 12) {
                                AvatarView(url: authVM.avatarURL, size: 88)
                                Text(p?.name.isEmpty == false ? p!.name : authVM.displayName)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                HStack(spacing: 8) {
                                    BadgeView(text: "Pro",      color: Color(hex: "6C63FF"))
                                    BadgeView(text: "Verified", color: Color(hex: "10B981"))
                                }
                            }
                            .padding(.vertical, 24).frame(maxWidth: .infinity)
                            .background(.white).clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                            // ── Banners ────────────────────────────────────
                            if savedBanner {
                                FeedbackBanner(icon: "checkmark.circle.fill", text: "Profile saved", color: Color(hex: "10B981"))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            if let err = errorMsg {
                                FeedbackBanner(icon: "exclamationmark.circle.fill", text: err, color: Color(hex: "EF4444"))
                            }

                            // ── Profile Info card ──────────────────────────
                            CardSection(title: "PROFILE INFO") {
                                if isEditing {
                                    VStack(spacing: 12) {
                                        EditField(icon: "person.fill",   placeholder: "Full Name",      text: $editName,  keyboard: .default)
                                        EditField(icon: "envelope.fill", placeholder: "Email Address",  text: $editEmail, keyboard: .emailAddress)
                                        EditField(icon: "phone.fill",    placeholder: "Contact Number", text: $editPhone, keyboard: .phonePad)
                                        PickerField(icon: "briefcase.fill", placeholder: "Job Role", options: JobRole.allCases, selected: Binding(
                                            get: { editJobRole }, set: { editJobRole = $0 }
                                        )) { $0.rawValue }
                                        PickerField(icon: "person.2.fill", placeholder: "Gender", options: Gender.allCases, selected: Binding(
                                            get: { editGender }, set: { editGender = $0 }
                                        )) { $0.rawValue }
                                    }.padding(16)
                                } else {
                                    InfoRow(icon: "person.fill",   color: Color(hex: "6C63FF"), label: "Full Name",      value: p?.name)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "envelope.fill", color: Color(hex: "3B82F6"), label: "Email",          value: p?.email.isEmpty == false ? p!.email : authVM.email)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "phone.fill",    color: Color(hex: "10B981"), label: "Contact Number", value: p?.phone)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "person.2.fill", color: Color(hex: "A78BFA"), label: "Gender",         value: p?.gender)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "briefcase.fill", color: Color(hex: "F59E0B"), label: "Job Role",      value: p?.job_role)
                                }
                            }

                            // ── Sign out ───────────────────────────────────
                            Button { authVM.signOut() } label: {
                                HStack {
                                    Image(systemName: "arrow.right.square.fill").font(.system(size: 16))
                                    Text("Sign Out").font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color(hex: "EF4444"))
                                .frame(maxWidth: .infinity).padding(.vertical, 18)
                                .background(Color(hex: "EF4444").opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "EF4444").opacity(0.2), lineWidth: 1))
                            }

                            Text("Version 1.0.0").font(.system(size: 12)).foregroundColor(.secondary).padding(.bottom, 8)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving { ProgressView().tint(Color(hex: "6C63FF")) }
                    else {
                        Button(isEditing ? "Save" : "Edit") { isEditing ? saveProfile() : startEditing() }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "6C63FF"))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") { isEditing = false; errorMsg = nil }
                            .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                    }
                }
            }
        }
        .task { await loadProfile() }
    }

    private func loadProfile() async {
        isLoading = true; defer { isLoading = false }
        do { authVM.remoteProfile = try await SupabaseService.shared.fetchProfile(userId: authVM.userId) }
        catch { errorMsg = error.localizedDescription }
    }

    private func startEditing() {
        editName    = p?.name.isEmpty    == false ? p!.name    : authVM.displayName
        editEmail   = p?.email.isEmpty   == false ? p!.email   : authVM.email
        editPhone   = p?.phone           ?? ""
        editJobRole = JobRole(rawValue: p?.job_role ?? "")
        editGender  = Gender(rawValue: p?.gender ?? "")
        isEditing   = true; errorMsg = nil
    }

    private func saveProfile() {
        Task {
            isSaving = true; defer { isSaving = false }
            do {
                let row = SupabaseService.ProfileRow(
                    id: p?.id, user_id: authVM.userId,
                    name:     editName.trimmingCharacters(in: .whitespaces),
                    email:    editEmail.trimmingCharacters(in: .whitespaces),
                    phone:    editPhone.trimmingCharacters(in: .whitespaces),
                    job_role: editJobRole?.rawValue ?? "",
                    gender:   editGender?.rawValue  ?? ""
                )
                authVM.remoteProfile = try await SupabaseService.shared.upsertProfile(row)
                isEditing = false; errorMsg = nil
                withAnimation { savedBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { savedBanner = false } }
            } catch { errorMsg = error.localizedDescription }
        }
    }
}

// ── Generic picker row ────────────────────────────────────────────────────────

struct PickerField<T: Hashable>: View {
    let icon: String
    let placeholder: String
    let options: [T]
    @Binding var selected: T?
    let label: (T) -> String
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: "6C63FF")).frame(width: 20)
                    Text(selected.map(label) ?? placeholder)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(selected == nil ? Color(.placeholderText) : .black)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "6C63FF"))
                }
                .padding(.horizontal, 14).padding(.vertical, 13)
                .background(Color(hex: "F5F5FF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(expanded ? 0.6 : 0.3), lineWidth: 1))
            }
            if expanded {
                VStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.offset) { i, opt in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selected = opt; expanded = false }
                        } label: {
                            HStack {
                                Text(label(opt)).font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                                Spacer()
                                if selected.map(label) == label(opt) {
                                    Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "6C63FF"))
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 13).background(.white)
                        }
                        if i < options.count - 1 { Divider().padding(.leading, 14) }
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

// ── Shared components ─────────────────────────────────────────────────────────

struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.secondary).padding(.horizontal, 4)
            VStack(spacing: 0) { content }
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
}

struct InfoRow: View {
    let icon: String; let color: Color; let label: String; let value: String?
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
                .frame(width: 32, height: 32).background(color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                Text(value?.isEmpty == false ? value! : "Not set")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(value?.isEmpty == false ? .black : Color(.placeholderText))
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct FeedbackBanner: View {
    let icon: String; let text: String; let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.vertical, 12)
        .background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EditField: View {
    let icon: String; let placeholder: String
    @Binding var text: String; let keyboard: UIKeyboardType
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: "6C63FF")).frame(width: 20)
            TextField(placeholder, text: $text).font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                .keyboardType(keyboard).autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
        }
        .padding(.horizontal, 14).padding(.vertical, 13).background(Color(hex: "F5F5FF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(0.3), lineWidth: 1))
    }
}

struct BadgeView: View {
    let text: String; let color: Color
    var body: some View {
        Text(text).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 4).background(color.opacity(0.12)).clipShape(Capsule())
    }
}

struct AvatarView: View {
    let url: URL?; let size: CGFloat
    var body: some View {
        AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: {
            LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Image(systemName: "person.fill").font(.system(size: size * 0.42)).foregroundColor(.white))
        }
        .frame(width: size, height: size).clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3)).shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}
