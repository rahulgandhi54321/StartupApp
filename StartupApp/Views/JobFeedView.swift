import SwiftUI

struct JobFeedView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm    = JobFeedViewModel()
    @ObservedObject  private var store = SavedJobsStore.shared
    @State private var showSaved      = false
    @State private var showFilters    = false

    var userRole:     String { authVM.remoteProfile?.job_role.isEmpty == false ? authVM.remoteProfile!.job_role : "software engineer" }
    var userLocation: String { authVM.remoteJobPref?.location.isEmpty  == false ? authVM.remoteJobPref!.location  : "India" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                VStack(spacing: 0) {
                    searchAndFilterBar
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

                    // Active filter chips
                    if vm.filters.isActive {
                        activeChips
                            .padding(.horizontal, 16).padding(.bottom, 8)
                    }

                    if vm.isLoading {
                        Spacer()
                        ProgressView("Finding jobs…").tint(Color(hex: "6C63FF"))
                        Spacer()
                    } else if let err = vm.errorMsg {
                        errorView(err)
                    } else if vm.jobs.isEmpty {
                        emptyView
                    } else {
                        jobList
                    }
                }
            }
            .navigationTitle("Job Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSaved = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "6C63FF"))
                            if !store.savedJobs.isEmpty {
                                Text("\(store.savedJobs.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white).padding(3)
                                    .background(Color(hex: "EF4444")).clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSaved) { SavedJobsView() }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filters: $vm.filters) {
                    Task { await vm.load(role: userRole, location: userLocation) }
                }
            }
            .task {
                // Wait for profile to be loaded before fetching jobs
                if authVM.remoteProfile == nil { await authVM.loadUserData() }
                await vm.load(role: userRole, location: userLocation)
            }
            .onChange(of: authVM.remoteProfile?.job_role) { _ in
                Task { await vm.load(role: userRole, location: userLocation) }
            }
        }
    }

    // ── Search + filter bar ────────────────────────────────────────────────────
    var searchAndFilterBar: some View {
        HStack(spacing: 10) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15)).foregroundColor(Color(hex: "6C63FF"))
                TextField("Search jobs…", text: $vm.searchText)
                    .font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                    .submitLabel(.search)
                    .onSubmit { Task { await vm.search() } }
                if !vm.searchText.isEmpty {
                    Button { vm.searchText = ""; Task { await vm.search() } } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            .frame(maxWidth: .infinity)

            // Filter button
            Button { showFilters = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17)).foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(vm.filters.isActive ? Color(hex: "6C63FF") : Color(hex: "6C63FF").opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "6C63FF").opacity(0.35), radius: 6, y: 3)
                    if vm.filters.activeCount > 0 {
                        Text("\(vm.filters.activeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white).padding(3)
                            .background(Color(hex: "EF4444")).clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
    }

    // ── Active filter chips ────────────────────────────────────────────────────
    var activeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if vm.filters.datePosted != .any {
                    FilterChip(label: vm.filters.datePosted.rawValue) {
                        vm.filters.datePosted = .any
                        Task { await vm.load(role: userRole, location: userLocation) }
                    }
                }
                if vm.filters.experience != .any {
                    FilterChip(label: vm.filters.experience.rawValue) {
                        vm.filters.experience = .any
                        Task { await vm.load(role: userRole, location: userLocation) }
                    }
                }
                if !vm.filters.locationOverride.isEmpty {
                    FilterChip(label: vm.filters.locationOverride) {
                        vm.filters.locationOverride = ""
                        Task { await vm.load(role: userRole, location: userLocation) }
                    }
                }
                Button {
                    vm.filters = JobFilters()
                    Task { await vm.load(role: userRole, location: userLocation) }
                } label: {
                    Text("Clear all")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "EF4444"))
                }
            }
        }
    }

    // ── Job list ───────────────────────────────────────────────────────────────
    var jobList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                // Count header
                HStack {
                    Image(systemName: "briefcase.fill").font(.system(size: 12)).foregroundColor(Color(hex: "6C63FF"))
                    Text("Showing \(vm.jobs.count) of \(vm.totalAvailable) jobs for \"\(userRole.isEmpty ? "All roles" : userRole)\"")
                        .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)

                ForEach(vm.jobs) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        JobCard(job: job)
                    }
                    .buttonStyle(.plain)
                }

                // Load more / end indicator
                if vm.jobs.count < vm.totalAvailable {
                    Button {
                        Task { await vm.loadMore() }
                    } label: {
                        HStack(spacing: 10) {
                            if vm.isLoadingMore {
                                ProgressView().tint(Color(hex: "6C63FF")).scaleEffect(0.85)
                                Text("Loading more…")
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Load more jobs")
                            }
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "6C63FF"))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color(hex: "6C63FF").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "6C63FF").opacity(0.2), lineWidth: 1))
                    }
                    .disabled(vm.isLoadingMore)
                    .onAppear { Task { await vm.loadMore() } } // auto-load when bottom reached
                } else if !vm.jobs.isEmpty {
                    Text("You've seen all \(vm.jobs.count) jobs")
                        .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 20)
        }
        .refreshable { await vm.refresh() }
    }

    // ── Empty ──────────────────────────────────────────────────────────────────
    var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "briefcase").font(.system(size: 48)).foregroundColor(Color(hex: "6C63FF").opacity(0.4))
            Text("No jobs found").font(.system(size: 18, weight: .semibold, design: .rounded))
            Text("Try adjusting your filters or search").font(.system(size: 14, design: .rounded)).foregroundColor(.secondary)
            Button("Retry") { Task { await vm.load(role: userRole, location: userLocation) } }
                .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                .padding(.horizontal, 32).padding(.vertical, 12)
                .background(Color(hex: "6C63FF")).clipShape(Capsule())
            Spacer()
        }.padding(32)
    }

    func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark").font(.system(size: 48)).foregroundColor(Color(hex: "EF4444").opacity(0.6))
            Text("Couldn't load jobs").font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(msg).font(.system(size: 13, design: .rounded)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("Try again") { Task { await vm.load(role: userRole, location: userLocation) } }
                .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.white)
                .padding(.horizontal, 32).padding(.vertical, 12)
                .background(Color(hex: "6C63FF")).clipShape(Capsule())
            Spacer()
        }
    }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded))
            Button { onRemove() } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundColor(Color(hex: "6C63FF"))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(hex: "6C63FF").opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color(hex: "6C63FF").opacity(0.3), lineWidth: 1))
    }
}

// ── Filter Sheet ──────────────────────────────────────────────────────────────

struct FilterSheet: View {
    @Binding var filters: JobFilters
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = JobFilters()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Date Posted ────────────────────────────────────
                        FilterSection(title: "DATE POSTED") {
                            VStack(spacing: 0) {
                                ForEach(Array(DatePostedFilter.allCases.enumerated()), id: \.element.id) { i, opt in
                                    Button {
                                        withAnimation { draft.datePosted = opt }
                                    } label: {
                                        HStack {
                                            Text(opt.rawValue)
                                                .font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                                            Spacer()
                                            if draft.datePosted == opt {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(hex: "6C63FF"))
                                            } else {
                                                Circle().stroke(Color(.systemGray4), lineWidth: 1.5).frame(width: 20, height: 20)
                                            }
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 14)
                                    }
                                    if i < DatePostedFilter.allCases.count - 1 {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                            .background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        }

                        // ── Experience ─────────────────────────────────────
                        FilterSection(title: "EXPERIENCE LEVEL") {
                            VStack(spacing: 0) {
                                ForEach(Array(ExperienceFilter.allCases.enumerated()), id: \.element.id) { i, opt in
                                    Button {
                                        withAnimation { draft.experience = opt }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(opt.rawValue)
                                                    .font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                                            }
                                            Spacer()
                                            if draft.experience == opt {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(hex: "6C63FF"))
                                            } else {
                                                Circle().stroke(Color(.systemGray4), lineWidth: 1.5).frame(width: 20, height: 20)
                                            }
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 14)
                                    }
                                    if i < ExperienceFilter.allCases.count - 1 {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                            .background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        }

                        // ── Location Override ──────────────────────────────
                        FilterSection(title: "LOCATION") {
                            HStack(spacing: 10) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14)).foregroundColor(Color(hex: "6C63FF")).frame(width: 20)
                                TextField("e.g. Mumbai, Delhi, Remote…", text: $draft.locationOverride)
                                    .font(.system(size: 15, design: .rounded)).foregroundColor(.black)
                                    .autocorrectionDisabled()
                                if !draft.locationOverride.isEmpty {
                                    Button { draft.locationOverride = "" } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 13)
                            .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        }

                        // ── Reset ──────────────────────────────────────────
                        if draft.isActive {
                            Button {
                                withAnimation { draft = JobFilters() }
                            } label: {
                                Text("Reset all filters")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "EF4444"))
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(Color(hex: "EF4444").opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filters = draft; onApply(); dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "6C63FF"))
                }
            }
        }
        .onAppear { draft = filters }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.secondary).padding(.horizontal, 4)
            content
        }
    }
}

// ── Job Card ──────────────────────────────────────────────────────────────────

struct JobCard: View {
    let job: Job
    @ObservedObject private var store = SavedJobsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Text(String(job.company.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(.black).lineLimit(2)
                    Text(job.company)
                        .font(.system(size: 13, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) { store.toggle(job) }
                } label: {
                    Image(systemName: store.isSaved(job) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(store.isSaved(job) ? Color(hex: "6C63FF") : .secondary)
                        .scaleEffect(store.isSaved(job) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: store.isSaved(job))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().padding(.leading, 74)

            HStack(spacing: 14) {
                if !job.location.isEmpty {
                    Label(job.location, systemImage: "location.fill")
                        .lineLimit(1)
                }
                if !job.salary.isEmpty {
                    Label(job.salary, systemImage: "indianrupeesign.circle.fill")
                }
                Spacer()
                if !job.posted_at.isEmpty {
                    Text(job.posted_at).font(.system(size: 11, design: .rounded)).foregroundColor(.secondary)
                }
            }
            .font(.system(size: 12, design: .rounded)).foregroundColor(.secondary)
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

// ── Job Detail ────────────────────────────────────────────────────────────────

struct JobDetailView: View {
    let job: Job
    @ObservedObject private var store = SavedJobsStore.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(job.title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.black)
                    Text(job.company).font(.system(size: 16, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                    HStack(spacing: 14) {
                        if !job.location.isEmpty { Label(job.location, systemImage: "location.fill") }
                        if !job.salary.isEmpty   { Label(job.salary,   systemImage: "indianrupeesign.circle.fill") }
                    }
                    .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                    if !job.posted_at.isEmpty {
                        Text("Posted \(job.posted_at)").font(.system(size: 12, design: .rounded)).foregroundColor(.secondary)
                    }
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)

                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Role").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(.secondary)
                    Text(job.description.isEmpty ? "No description available." : job.description + "…")
                        .font(.system(size: 15, design: .rounded)).foregroundColor(.black).lineSpacing(4)
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)

                VStack(spacing: 12) {
                    if let url = URL(string: job.url), !job.url.isEmpty {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("Apply Now").font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    Button {
                        withAnimation(.spring(response: 0.3)) { store.toggle(job) }
                    } label: {
                        HStack {
                            Image(systemName: store.isSaved(job) ? "bookmark.fill" : "bookmark")
                            Text(store.isSaved(job) ? "Saved" : "Save Job").font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(store.isSaved(job) ? Color(hex: "6C63FF") : .secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color(hex: "6C63FF").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "6C63FF").opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "F5F5FF").ignoresSafeArea())
        .navigationTitle("Job Details").navigationBarTitleDisplayMode(.inline)
    }
}

// ── Saved Jobs ────────────────────────────────────────────────────────────────

struct SavedJobsView: View {
    @ObservedObject private var store = SavedJobsStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                if store.savedJobs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark").font(.system(size: 48)).foregroundColor(Color(hex: "6C63FF").opacity(0.3))
                        Text("No saved jobs yet").font(.system(size: 18, weight: .semibold, design: .rounded))
                        Text("Tap the bookmark on any job to save it").font(.system(size: 14, design: .rounded)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }.padding(32)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(store.savedJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) { JobCard(job: job) }
                                    .buttonStyle(.plain)
                            }
                        }.padding(16)
                    }
                }
            }
            .navigationTitle("Saved Jobs").navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: "6C63FF"))
                }
            }
        }
    }
}
