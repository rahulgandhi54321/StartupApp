import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    // ── Edit state: Profile Info ───────────────────────────────────────────────
    @State private var editingSection: EditSection? = nil
    @State private var editName     = ""
    @State private var editEmail    = ""
    @State private var editPhone    = ""
    @State private var editJobRole: JobRole?  = nil
    @State private var editGender:  Gender?   = nil

    // ── Edit state: Job Preferences ───────────────────────────────────────────
    @State private var editCurrentCTC  = ""
    @State private var editExpectedCTC = ""
    @State private var editLocation: PreferredLocation? = nil
    @State private var editNotice:   NoticePeriod?      = nil
    @State private var editExperience = ""
    @State private var editLinkedIn   = ""
    @State private var editSkills     = ""

    // ── UI state ──────────────────────────────────────────────────────────────
    @State private var isLoading      = false
    @State private var isSaving       = false
    @State private var isUploadingPDF = false
    @State private var savedBanner    = false
    @State private var errorMsg: String?
    @State private var showDocPicker  = false
    @State private var showSignOutAlert = false

    enum EditSection { case profile, jobPref }

    var p: SupabaseService.ProfileRow?  { authVM.remoteProfile }
    var j: SupabaseService.JobPrefRow?  { authVM.remoteJobPref }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading profile…").tint(Color(hex: "6C63FF"))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            // ── Avatar hero ────────────────────────────────
                            avatarHero

                            // ── Banners ────────────────────────────────────
                            if savedBanner {
                                FeedbackBanner(icon: "checkmark.circle.fill", text: "Saved successfully", color: Color(hex: "10B981"))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            if let err = errorMsg {
                                FeedbackBanner(icon: "exclamationmark.circle.fill", text: err, color: Color(hex: "EF4444"))
                            }

                            // ── Profile Info ───────────────────────────────
                            profileInfoCard

                            // ── Job Preferences ────────────────────────────
                            jobPreferenceCard

                            // ── Sign Out ───────────────────────────────────
                            Button { showSignOutAlert = true } label: {
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
            .sheet(isPresented: $showDocPicker) { DocumentPicker { uploadPDF(url: $0) } }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { authVM.signOut() }
            } message: { Text("Are you sure you want to sign out?") }
        }
        .task { await loadAll() }
    }

    // ── Avatar hero ────────────────────────────────────────────────────────────

    var avatarHero: some View {
        VStack(spacing: 12) {
            AvatarView(url: authVM.avatarURL, size: 88)
            Text(p?.name.isEmpty == false ? p!.name : authVM.displayName)
                .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.black)
            HStack(spacing: 8) {
                BadgeView(text: "Pro",      color: Color(hex: "6C63FF"))
                BadgeView(text: "Verified", color: Color(hex: "10B981"))
            }
        }
        .padding(.vertical, 24).frame(maxWidth: .infinity)
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // ── Profile Info card ──────────────────────────────────────────────────────

    var profileInfoCard: some View {
        CardSection(title: "PROFILE INFO", buttonLabel: editingSection == .profile ? nil : "Edit") {
            editingSection == .profile ? startSaveButton(.profile) : nil
        } content: {
            if editingSection == .profile {
                VStack(spacing: 12) {
                    EditField(icon: "person.fill",   placeholder: "Full Name",      text: $editName,  keyboard: .default)
                    EditField(icon: "envelope.fill", placeholder: "Email Address",  text: $editEmail, keyboard: .emailAddress)
                    EditField(icon: "phone.fill",    placeholder: "Contact Number", text: $editPhone, keyboard: .phonePad)
                    PickerField(icon: "person.2.fill",  placeholder: "Gender",   options: Gender.allCases,  selected: $editGender)  { $0.rawValue }
                    PickerField(icon: "briefcase.fill", placeholder: "Job Role", options: JobRole.allCases, selected: $editJobRole) { $0.rawValue }
                }.padding(16)
            } else {
                InfoRow(icon: "person.fill",    color: Color(hex: "6C63FF"), label: "Full Name",      value: p?.name)
                Divider().padding(.leading, 52)
                InfoRow(icon: "envelope.fill",  color: Color(hex: "3B82F6"), label: "Email",          value: p?.email.isEmpty == false ? p!.email : authVM.email)
                Divider().padding(.leading, 52)
                InfoRow(icon: "phone.fill",     color: Color(hex: "10B981"), label: "Contact Number", value: p?.phone)
                Divider().padding(.leading, 52)
                InfoRow(icon: "person.2.fill",  color: Color(hex: "A78BFA"), label: "Gender",         value: p?.gender)
                Divider().padding(.leading, 52)
                InfoRow(icon: "briefcase.fill", color: Color(hex: "F59E0B"), label: "Job Role",       value: p?.job_role)
            }
        }
        .overlay(alignment: .topTrailing) { sectionToolbar(for: .profile) }
    }

    // ── Job Preference card ────────────────────────────────────────────────────

    var jobPreferenceCard: some View {
        CardSection(title: "JOB PREFERENCES", buttonLabel: nil, button: { nil }) {
            if editingSection == .jobPref {
                VStack(spacing: 12) {
                    // Resume upload
                    Button { showDocPicker = true } label: { resumeButton }
                        .disabled(isUploadingPDF)

                    EditField(icon: "indianrupeesign.circle.fill", placeholder: "Current CTC (e.g. 12 LPA)",  text: $editCurrentCTC,  keyboard: .default)
                    EditField(icon: "arrow.up.circle.fill",        placeholder: "Expected CTC (e.g. 18 LPA)", text: $editExpectedCTC, keyboard: .default)
                    PickerField(icon: "location.fill", placeholder: "Preferred Location", options: PreferredLocation.allCases, selected: $editLocation) { $0.rawValue }
                    PickerField(icon: "clock.fill",    placeholder: "Notice Period",       options: NoticePeriod.allCases,      selected: $editNotice)   { $0.rawValue }
                    EditField(icon: "calendar",       placeholder: "Years of Experience", text: $editExperience, keyboard: .numberPad)
                    EditField(icon: "link.circle.fill", placeholder: "LinkedIn URL",       text: $editLinkedIn,   keyboard: .URL)
                    EditField(icon: "tag.fill",          placeholder: "Skills (comma separated)", text: $editSkills, keyboard: .default)
                }.padding(16)
            } else {
                resumeInfoRow
                Divider().padding(.leading, 52)
                InfoRow(icon: "indianrupeesign.circle.fill", color: Color(hex: "10B981"), label: "Current CTC",       value: j?.current_ctc)
                Divider().padding(.leading, 52)
                InfoRow(icon: "arrow.up.circle.fill",        color: Color(hex: "6C63FF"), label: "Expected CTC",      value: j?.expected_ctc)
                Divider().padding(.leading, 52)
                InfoRow(icon: "location.fill",               color: Color(hex: "EF4444"), label: "Location",          value: j?.location)
                Divider().padding(.leading, 52)
                InfoRow(icon: "clock.fill",                  color: Color(hex: "F59E0B"), label: "Notice Period",     value: j?.notice_period)
                Divider().padding(.leading, 52)
                InfoRow(icon: "calendar",                    color: Color(hex: "3B82F6"), label: "Experience",        value: j?.experience.isEmpty == false ? "\(j!.experience) yrs" : nil)
                Divider().padding(.leading, 52)
                InfoRow(icon: "link.circle.fill",            color: Color(hex: "3B82F6"), label: "LinkedIn",          value: j?.linkedin_url)
                Divider().padding(.leading, 52)
                InfoRow(icon: "tag.fill",                    color: Color(hex: "A78BFA"), label: "Skills",            value: j?.skills)
            }
        }
        .overlay(alignment: .topTrailing) { sectionToolbar(for: .jobPref) }
    }

    var resumeInfoRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.fill").font(.system(size: 15)).foregroundColor(Color(hex: "EF4444"))
                .frame(width: 32, height: 32).background(Color(hex: "EF4444").opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text("Resume").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                Text(j?.resume_url.isEmpty == false ? "Uploaded ✓" : "Not uploaded")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(j?.resume_url.isEmpty == false ? Color(hex: "10B981") : Color(.placeholderText))
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    var resumeButton: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill").font(.system(size: 20)).foregroundColor(Color(hex: "EF4444"))
            VStack(alignment: .leading, spacing: 2) {
                if isUploadingPDF {
                    Text("Uploading…").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                    ProgressView().tint(Color(hex: "6C63FF")).scaleEffect(0.8)
                } else if j?.resume_url.isEmpty == false {
                    Text("Resume uploaded ✓").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "10B981"))
                    Text("Tap to replace").font(.system(size: 12)).foregroundColor(.secondary)
                } else {
                    Text("Upload Resume (PDF)").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                    Text("Tap to choose file").font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "arrow.up.circle.fill").font(.system(size: 22)).foregroundColor(Color(hex: "6C63FF").opacity(0.5))
        }
        .padding(14).background(Color(hex: "F5F5FF"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])).foregroundColor(Color(hex: "6C63FF").opacity(0.3)))
    }

    // ── Section toolbar (Edit / Save / Cancel) ─────────────────────────────────

    @ViewBuilder
    func sectionToolbar(for section: EditSection) -> some View {
        if isSaving && editingSection == section {
            ProgressView().tint(Color(hex: "6C63FF")).padding(16)
        } else if editingSection == section {
            HStack(spacing: 12) {
                Button("Cancel") { editingSection = nil; errorMsg = nil }
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                Button("Save") { section == .profile ? saveProfile() : saveJobPref() }
                    .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
            }.padding(16)
        } else {
            Button("Edit") { startEditing(section) }
                .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                .padding(16)
        }
    }

    func startSaveButton(_ section: EditSection) -> AnyView? { nil }

    // ── Load ───────────────────────────────────────────────────────────────────

    func loadAll() async {
        isLoading = true; defer { isLoading = false }
        async let profile = SupabaseService.shared.fetchProfile(userId: authVM.userId)
        async let jobPref = SupabaseService.shared.fetchJobPref(userId: authVM.userId)
        do {
            authVM.remoteProfile = try await profile
            authVM.remoteJobPref = (try? await jobPref)
        } catch {
            errorMsg = error.localizedDescription
        }
    }

    // ── Start editing ──────────────────────────────────────────────────────────

    func startEditing(_ section: EditSection) {
        errorMsg = nil
        if section == .profile {
            editName    = p?.name.isEmpty    == false ? p!.name    : authVM.displayName
            editEmail   = p?.email.isEmpty   == false ? p!.email   : authVM.email
            editPhone   = p?.phone           ?? ""
            editJobRole = JobRole(rawValue:  p?.job_role ?? "")
            editGender  = Gender(rawValue:   p?.gender   ?? "")
        } else {
            editCurrentCTC  = j?.current_ctc   ?? ""
            editExpectedCTC = j?.expected_ctc  ?? ""
            editLocation    = PreferredLocation(rawValue: j?.location      ?? "")
            editNotice      = NoticePeriod(rawValue:      j?.notice_period ?? "")
            editExperience  = j?.experience    ?? ""
            editLinkedIn    = j?.linkedin_url  ?? ""
            editSkills      = j?.skills        ?? ""
        }
        editingSection = section
    }

    // ── Save Profile ───────────────────────────────────────────────────────────

    func saveProfile() {
        Task {
            isSaving = true; defer { isSaving = false }
            do {
                authVM.remoteProfile = try await SupabaseService.shared.upsertProfile(
                    SupabaseService.ProfileRow(
                        id: p?.id, user_id: authVM.userId,
                        name:     editName.trimmingCharacters(in: .whitespaces),
                        email:    editEmail.trimmingCharacters(in: .whitespaces),
                        phone:    editPhone.trimmingCharacters(in: .whitespaces),
                        job_role: editJobRole?.rawValue ?? "",
                        gender:   editGender?.rawValue  ?? ""
                    )
                )
                editingSection = nil; errorMsg = nil
                showBanner()
            } catch { errorMsg = error.localizedDescription }
        }
    }

    // ── Save Job Preferences ───────────────────────────────────────────────────

    func saveJobPref() {
        Task {
            isSaving = true; defer { isSaving = false }
            do {
                authVM.remoteJobPref = try await SupabaseService.shared.upsertJobPref(
                    SupabaseService.JobPrefRow(
                        id: j?.id, user_id: authVM.userId,
                        resume_url:    j?.resume_url    ?? "",
                        current_ctc:   editCurrentCTC.trimmingCharacters(in: .whitespaces),
                        expected_ctc:  editExpectedCTC.trimmingCharacters(in: .whitespaces),
                        location:      editLocation?.rawValue  ?? "",
                        notice_period: editNotice?.rawValue    ?? "",
                        experience:    editExperience.trimmingCharacters(in: .whitespaces),
                        linkedin_url:  editLinkedIn.trimmingCharacters(in: .whitespaces),
                        skills:        editSkills.trimmingCharacters(in: .whitespaces)
                    )
                )
                editingSection = nil; errorMsg = nil
                showBanner()
            } catch { errorMsg = error.localizedDescription }
        }
    }

    // ── Resume upload ──────────────────────────────────────────────────────────

    func uploadPDF(url: URL) {
        Task {
            isUploadingPDF = true; defer { isUploadingPDF = false }
            do {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                let publicURL = try await SupabaseService.shared.uploadResume(userId: authVM.userId, pdfData: data)
                authVM.remoteJobPref = try await SupabaseService.shared.upsertJobPref(
                    SupabaseService.JobPrefRow(
                        id: j?.id, user_id: authVM.userId,
                        resume_url:    publicURL,
                        current_ctc:   j?.current_ctc   ?? "",
                        expected_ctc:  j?.expected_ctc  ?? "",
                        location:      j?.location       ?? "",
                        notice_period: j?.notice_period  ?? "",
                        experience:    j?.experience     ?? "",
                        linkedin_url:  j?.linkedin_url   ?? "",
                        skills:        j?.skills         ?? ""
                    )
                )
                showBanner()
            } catch { errorMsg = "Upload failed: \(error.localizedDescription)" }
        }
    }

    func showBanner() {
        withAnimation { savedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { savedBanner = false } }
    }
}

// ── CardSection ───────────────────────────────────────────────────────────────

struct CardSection<Content: View>: View {
    let title: String
    var buttonLabel: String?
    var button: () -> AnyView?
    @ViewBuilder let content: Content

    init(title: String, buttonLabel: String? = nil, button: @escaping () -> AnyView? = { nil }, @ViewBuilder content: () -> Content) {
        self.title = title; self.buttonLabel = buttonLabel; self.button = button; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.secondary).padding(.horizontal, 4)
            VStack(spacing: 0) { content }
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
}

// ── Shared components ─────────────────────────────────────────────────────────

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

struct PickerField<T: Hashable>: View {
    let icon: String; let placeholder: String
    let options: [T]; @Binding var selected: T?
    let label: (T) -> String
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.3)) { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: "6C63FF")).frame(width: 20)
                    Text(selected.map(label) ?? placeholder).font(.system(size: 15, design: .rounded))
                        .foregroundColor(selected == nil ? Color(.placeholderText) : .black)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "6C63FF"))
                }
                .padding(.horizontal, 14).padding(.vertical, 13).background(Color(hex: "F5F5FF"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(expanded ? 0.6 : 0.3), lineWidth: 1))
            }
            if expanded {
                VStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.offset) { i, opt in
                        Button { withAnimation(.spring(response: 0.3)) { selected = opt; expanded = false } } label: {
                            HStack {
                                Text(label(opt)).font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                                Spacer()
                                if selected.map(label) == label(opt) {
                                    Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "6C63FF"))
                                }
                            }.padding(.horizontal, 14).padding(.vertical, 13).background(.white)
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

struct EditField: View {
    let icon: String; let placeholder: String
    @Binding var text: String; let keyboard: UIKeyboardType
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: "6C63FF")).frame(width: 20)
            TextField(placeholder, text: $text).font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                .keyboardType(keyboard).autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress || keyboard == .URL ? .never : .words)
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

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        p.delegate = context.coordinator; p.allowsMultipleSelection = false; return p
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }; onPick(url)
        }
    }
}
