import SwiftUI
import UniformTypeIdentifiers

struct JobPreferenceView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var isEditing       = false
    @State private var editCurrentCTC  = ""
    @State private var editExpectedCTC = ""
    @State private var editLocation: PreferredLocation? = nil
    @State private var editNotice: NoticePeriod?        = nil
    @State private var editExperience  = ""
    @State private var editLinkedIn    = ""
    @State private var editSkills      = ""
    @State private var resumeFileName  = ""

    @State private var isLoading       = false
    @State private var isSaving        = false
    @State private var isUploadingPDF  = false
    @State private var savedBanner     = false
    @State private var errorMsg: String?
    @State private var showDocPicker   = false

    var j: SupabaseService.JobPrefRow? { authVM.remoteJobPref }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading…").tint(Color(hex: "6C63FF"))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {

                            // ── Header card ────────────────────────────────
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 24)).foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Job Preferences")
                                        .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.black)
                                    Text("Used for auto-applying to job portals")
                                        .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(20).background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                            // ── Banners ────────────────────────────────────
                            if savedBanner {
                                FeedbackBanner(icon: "checkmark.circle.fill", text: "Preferences saved", color: Color(hex: "10B981"))
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            if let err = errorMsg {
                                FeedbackBanner(icon: "exclamationmark.circle.fill", text: err, color: Color(hex: "EF4444"))
                            }

                            // ── Resume ─────────────────────────────────────
                            CardSection(title: "RESUME") {
                                VStack(spacing: 12) {
                                    // Upload button
                                    Button { showDocPicker = true } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(hex: "EF4444").opacity(0.1))
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: "doc.fill")
                                                    .font(.system(size: 18)).foregroundColor(Color(hex: "EF4444"))
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                if isUploadingPDF {
                                                    Text("Uploading…").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                                                    ProgressView().tint(Color(hex: "6C63FF")).scaleEffect(0.8)
                                                } else if let url = j?.resume_url, !url.isEmpty {
                                                    Text("Resume uploaded ✓")
                                                        .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "10B981"))
                                                    Text("Tap to replace").font(.system(size: 12)).foregroundColor(.secondary)
                                                } else {
                                                    Text("Upload Resume (PDF)")
                                                        .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                                                    Text("Tap to choose file").font(.system(size: 12)).foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(.system(size: 22)).foregroundColor(Color(hex: "6C63FF").opacity(0.4))
                                        }
                                        .padding(16).background(Color(hex: "F5F5FF"))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "6C63FF").opacity(0.25), lineWidth: 1.5).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                                    }
                                    .disabled(isUploadingPDF)
                                }
                                .padding(16)
                            }

                            // ── CTC ────────────────────────────────────────
                            CardSection(title: "COMPENSATION") {
                                if isEditing {
                                    VStack(spacing: 12) {
                                        EditField(icon: "indianrupeesign.circle.fill", placeholder: "Current CTC (e.g. 12 LPA)", text: $editCurrentCTC, keyboard: .default)
                                        EditField(icon: "indianrupeesign.circle.fill", placeholder: "Expected CTC (e.g. 18 LPA)", text: $editExpectedCTC, keyboard: .default)
                                    }.padding(16)
                                } else {
                                    InfoRow(icon: "indianrupeesign.circle.fill", color: Color(hex: "10B981"), label: "Current CTC",  value: j?.current_ctc)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "arrow.up.circle.fill",        color: Color(hex: "6C63FF"), label: "Expected CTC", value: j?.expected_ctc)
                                }
                            }

                            // ── Location & Availability ────────────────────
                            CardSection(title: "AVAILABILITY") {
                                if isEditing {
                                    VStack(spacing: 12) {
                                        PickerField(icon: "location.fill", placeholder: "Preferred Location",
                                                    options: PreferredLocation.allCases, selected: $editLocation) { $0.rawValue }
                                        PickerField(icon: "clock.fill", placeholder: "Notice Period",
                                                    options: NoticePeriod.allCases, selected: $editNotice) { $0.rawValue }
                                        EditField(icon: "calendar", placeholder: "Years of Experience (e.g. 3)", text: $editExperience, keyboard: .numbersAndPunctuation)
                                    }.padding(16)
                                } else {
                                    InfoRow(icon: "location.fill", color: Color(hex: "EF4444"), label: "Location",           value: j?.location)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "clock.fill",    color: Color(hex: "F59E0B"), label: "Notice Period",      value: j?.notice_period)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "calendar",      color: Color(hex: "3B82F6"), label: "Experience",         value: j?.experience.isEmpty == false ? "\(j!.experience) years" : nil)
                                }
                            }

                            // ── Online presence ────────────────────────────
                            CardSection(title: "ONLINE PRESENCE") {
                                if isEditing {
                                    VStack(spacing: 12) {
                                        EditField(icon: "link.circle.fill",  placeholder: "LinkedIn URL", text: $editLinkedIn, keyboard: .URL)
                                        EditField(icon: "tag.fill",          placeholder: "Key Skills (comma separated)", text: $editSkills, keyboard: .default)
                                    }.padding(16)
                                } else {
                                    InfoRow(icon: "link.circle.fill", color: Color(hex: "3B82F6"), label: "LinkedIn",  value: j?.linkedin_url)
                                    Divider().padding(.leading, 52)
                                    InfoRow(icon: "tag.fill",         color: Color(hex: "A78BFA"), label: "Skills",    value: j?.skills)
                                }
                            }

                            Text("Version 1.0.0").font(.system(size: 12)).foregroundColor(.secondary).padding(.bottom, 8)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Job Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving { ProgressView().tint(Color(hex: "6C63FF")) }
                    else {
                        Button(isEditing ? "Save" : "Edit") { isEditing ? savePrefs() : startEditing() }
                            .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") { isEditing = false; errorMsg = nil }
                            .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showDocPicker) {
                DocumentPicker { url in uploadPDF(url: url) }
            }
        }
        .task { await loadPrefs() }
    }

    private func loadPrefs() async {
        isLoading = true; defer { isLoading = false }
        do { authVM.remoteJobPref = try await SupabaseService.shared.fetchJobPref(userId: authVM.userId) }
        catch { errorMsg = error.localizedDescription }
    }

    private func startEditing() {
        editCurrentCTC  = j?.current_ctc  ?? ""
        editExpectedCTC = j?.expected_ctc ?? ""
        editLocation    = PreferredLocation(rawValue: j?.location      ?? "")
        editNotice      = NoticePeriod(rawValue: j?.notice_period ?? "")
        editExperience  = j?.experience   ?? ""
        editLinkedIn    = j?.linkedin_url ?? ""
        editSkills      = j?.skills       ?? ""
        isEditing = true; errorMsg = nil
    }

    private func savePrefs() {
        Task {
            isSaving = true; defer { isSaving = false }
            do {
                let row = SupabaseService.JobPrefRow(
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
                authVM.remoteJobPref = try await SupabaseService.shared.upsertJobPref(row)
                isEditing = false; errorMsg = nil
                withAnimation { savedBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { savedBanner = false } }
            } catch { errorMsg = error.localizedDescription }
        }
    }

    private func uploadPDF(url: URL) {
        Task {
            isUploadingPDF = true; defer { isUploadingPDF = false }
            do {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                let publicURL = try await SupabaseService.shared.uploadResume(userId: authVM.userId, pdfData: data)
                // Save resume_url immediately
                let row = SupabaseService.JobPrefRow(
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
                authVM.remoteJobPref = try await SupabaseService.shared.upsertJobPref(row)
                withAnimation { savedBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { savedBanner = false } }
            } catch { errorMsg = "Upload failed: \(error.localizedDescription)" }
        }
    }
}

