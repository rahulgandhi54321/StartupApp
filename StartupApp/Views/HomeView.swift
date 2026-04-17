import SwiftUI

// ── Home Tab ──────────────────────────────────────────────────────────────────

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject private var store = AppliedJobsStore.shared
    @State private var selectedJob: AppliedJob? = nil
    @State private var showStatusPicker = false

    // Greeting by time of day
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        case 17..<21: return "Good evening 👋"
        default:      return "Hey there 👋"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Header card ────────────────────────────────────
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greeting)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                Text(authVM.displayName.components(separatedBy: " ").first ?? "")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                if let role = authVM.remoteProfile?.job_role, !role.isEmpty {
                                    Text(role)
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(Color(hex: "6C63FF"))
                                }
                            }
                            Spacer()
                            AvatarView(url: authVM.avatarURL, size: 50)
                        }
                        .padding(20).background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

                        // ── Stats row ──────────────────────────────────────
                        HStack(spacing: 12) {
                            StatCard(
                                value: "\(store.totalApplied)",
                                label: "Total Applied",
                                icon: "paperplane.fill",
                                color: Color(hex: "6C63FF")
                            )
                            StatCard(
                                value: "\(store.appliedThisWeek)",
                                label: "This Week",
                                icon: "calendar.badge.clock",
                                color: Color(hex: "10B981")
                            )
                            StatCard(
                                value: "\(store.count(for: .interviewing))",
                                label: "Interviews",
                                icon: "person.2.fill",
                                color: Color(hex: "F59E0B")
                            )
                        }

                        // ── Pipeline ──────────────────────────────────────
                        if store.totalApplied > 0 {
                            PipelineCard(store: store)
                        }

                        // ── Recent Applications ────────────────────────────
                        if store.appliedJobs.isEmpty {
                            EmptyApplicationsCard()
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Recent Applications")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    Spacer()
                                    Text("\(store.totalApplied) total")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 2)

                                ForEach(store.appliedJobs.prefix(20)) { job in
                                    AppliedJobRow(job: job) { updated in
                                        store.updateStatus(id: updated.id, status: updated.status)
                                    }
                                }
                            }
                        }

                        // ── Top Companies ──────────────────────────────────
                        if store.topCompanies.count >= 2 {
                            TopCompaniesCard(companies: store.topCompanies)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("").navigationBarHidden(true)
        }
    }
}

// ── Pipeline card ─────────────────────────────────────────────────────────────

struct PipelineCard: View {
    @ObservedObject var store: AppliedJobsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Application Pipeline")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(ApplicationStatus.allCases, id: \.self) { status in
                    let count = store.count(for: status)
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: status.color).opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: status.icon)
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: status.color))
                        }
                        Text("\(count)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        Text(status.rawValue)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: 60)
                    }
                    .frame(maxWidth: .infinity)

                    if status != .rejected {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.secondary.opacity(0.4))
                    }
                }
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// ── Applied job row ───────────────────────────────────────────────────────────

struct AppliedJobRow: View {
    let job: AppliedJob
    let onStatusChange: (AppliedJob) -> Void

    @State private var showStatusMenu = false

    var body: some View {
        HStack(spacing: 14) {
            // Company avatar
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "6C63FF").opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(job.company.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "6C63FF"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(job.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Text(job.company)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                Text(relativeDate(job.appliedAt))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            // Status badge — tappable
            Button {
                showStatusMenu = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: job.status.icon)
                        .font(.system(size: 10))
                    Text(job.status.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color(hex: job.status.color))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color(hex: job.status.color).opacity(0.12))
                .clipShape(Capsule())
            }
            .confirmationDialog("Update Status", isPresented: $showStatusMenu, titleVisibility: .visible) {
                ForEach(ApplicationStatus.allCases, id: \.self) { s in
                    Button(s.rawValue) {
                        var updated = job
                        updated.status = s
                        onStatusChange(updated)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func relativeDate(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 3600  { return "\(diff / 60)m ago" }
        if diff < 86400 { return "\(diff / 3600)h ago" }
        return "\(diff / 86400)d ago"
    }
}

// ── Top companies card ────────────────────────────────────────────────────────

struct TopCompaniesCard: View {
    let companies: [(company: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Companies Applied")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            let maxCount = companies.first?.count ?? 1
            ForEach(companies, id: \.company) { item in
                HStack(spacing: 10) {
                    Text(item.company)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .frame(width: 110, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "6C63FF").opacity(0.15))
                            .frame(width: geo.size.width, height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "6C63FF"))
                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount), height: 8)
                    }
                    .frame(height: 8)
                    Text("\(item.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "6C63FF"))
                        .frame(width: 20, alignment: .trailing)
                }
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// ── Empty state ───────────────────────────────────────────────────────────────

struct EmptyApplicationsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "6C63FF").opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Color(hex: "6C63FF").opacity(0.6))
            }
            Text("No applications yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text("Browse jobs and tap \"Apply\" to start tracking your applications here.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

struct StatCard: View {
    let value: String; let label: String; let icon: String; let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.black)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
