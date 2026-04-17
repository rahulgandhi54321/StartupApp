import SwiftUI

struct JobFeedView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm    = JobFeedViewModel()
    @StateObject private var store = SavedJobsStore.shared
    @State private var showSaved   = false

    // Derive role & location from the user's profile
    var userRole:     String { authVM.remoteProfile?.job_role   ?? authVM.remoteJobPref?.location ?? "" }
    var userLocation: String { authVM.remoteJobPref?.location   ?? "India" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Search bar ─────────────────────────────────────────
                    searchBar
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)

                    // ── Content ────────────────────────────────────────────
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
                    Button {
                        showSaved = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "6C63FF"))
                            if !store.savedJobs.isEmpty {
                                Text("\(store.savedJobs.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color(hex: "EF4444"))
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSaved) { SavedJobsView() }
            .task {
                await vm.load(role: userRole, location: userLocation)
            }
        }
    }

    // ── Search bar ─────────────────────────────────────────────────────────────
    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "6C63FF"))
            TextField("Search jobs…", text: $vm.searchText)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.black)
                .submitLabel(.search)
                .onSubmit { Task { await vm.search() } }
            if !vm.searchText.isEmpty {
                Button { vm.searchText = ""; Task { await vm.search() } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // ── Job list ───────────────────────────────────────────────────────────────
    var jobList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                // Role pill header
                HStack {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6C63FF"))
                    Text("\(vm.jobs.count) jobs for \"\(userRole.isEmpty ? "All roles" : userRole)\"")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)

                ForEach(vm.jobs) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        JobCard(job: job)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 20)
        }
        .refreshable { await vm.load(role: userRole, location: userLocation) }
    }

    // ── Empty ──────────────────────────────────────────────────────────────────
    var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "briefcase").font(.system(size: 48)).foregroundColor(Color(hex: "6C63FF").opacity(0.4))
            Text("No jobs found").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundColor(.black)
            Text("Try a different search or check back later")
                .font(.system(size: 14, design: .rounded)).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("Retry") { Task { await vm.load(role: userRole, location: userLocation) } }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white).padding(.horizontal, 32).padding(.vertical, 12)
                .background(Color(hex: "6C63FF")).clipShape(Capsule())
            Spacer()
        }
        .padding(32)
    }

    func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark").font(.system(size: 48)).foregroundColor(Color(hex: "EF4444").opacity(0.6))
            Text("Couldn't load jobs").font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(msg).font(.system(size: 13, design: .rounded)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("Try again") { Task { await vm.load(role: userRole, location: userLocation) } }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white).padding(.horizontal, 32).padding(.vertical, 12)
                .background(Color(hex: "6C63FF")).clipShape(Capsule())
            Spacer()
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
                // Company initial avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Text(String(job.company.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(2)
                    Text(job.company)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color(hex: "6C63FF"))
                }

                Spacer()

                // Save button
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

            // Location + salary row
            HStack(spacing: 16) {
                Label(job.location.isEmpty ? "Remote" : job.location, systemImage: "location.fill")
                if !job.salary.isEmpty {
                    Label(job.salary, systemImage: "indianrupeesign.circle.fill")
                }
                Spacer()
                if !job.posted_at.isEmpty {
                    Text(job.posted_at)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

// ── Job Detail ────────────────────────────────────────────────────────────────

struct JobDetailView: View {
    let job: Job
    @ObservedObject private var store = SavedJobsStore.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(job.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    Text(job.company)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Color(hex: "6C63FF"))

                    HStack(spacing: 16) {
                        Label(job.location.isEmpty ? "Remote" : job.location, systemImage: "location.fill")
                        if !job.salary.isEmpty {
                            Label(job.salary, systemImage: "indianrupeesign.circle.fill")
                        }
                    }
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)

                    if !job.posted_at.isEmpty {
                        Text("Posted \(job.posted_at)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Role")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(job.description.isEmpty ? "No description available." : job.description + "…")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.black)
                        .lineSpacing(4)
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)

                // Buttons
                VStack(spacing: 12) {
                    if let url = URL(string: job.url), !job.url.isEmpty {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("Apply Now")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.3)) { store.toggle(job) }
                    } label: {
                        HStack {
                            Image(systemName: store.isSaved(job) ? "bookmark.fill" : "bookmark")
                            Text(store.isSaved(job) ? "Saved" : "Save Job")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
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
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
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
                        Text("Tap the bookmark icon on any job to save it")
                            .font(.system(size: 14, design: .rounded)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(store.savedJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCard(job: job)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Saved Jobs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "6C63FF"))
                }
            }
        }
    }
}
