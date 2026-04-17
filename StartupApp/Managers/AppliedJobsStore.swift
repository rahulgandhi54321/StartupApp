import Foundation

// ── Application status ────────────────────────────────────────────────────────

enum ApplicationStatus: String, Codable, CaseIterable {
    case applied      = "Applied"
    case interviewing = "Interviewing"
    case offer        = "Offer Received"
    case rejected     = "Rejected"

    var icon: String {
        switch self {
        case .applied:      return "paperplane.fill"
        case .interviewing: return "person.2.fill"
        case .offer:        return "star.fill"
        case .rejected:     return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .applied:      return "6C63FF"
        case .interviewing: return "F59E0B"
        case .offer:        return "10B981"
        case .rejected:     return "EF4444"
        }
    }
}

// ── Applied job record ────────────────────────────────────────────────────────

struct AppliedJob: Identifiable, Codable, Equatable {
    let id:        String    // = job.id
    let title:     String
    let company:   String
    let url:       String
    let location:  String
    let appliedAt: Date
    var status:    ApplicationStatus

    static func == (lhs: AppliedJob, rhs: AppliedJob) -> Bool { lhs.id == rhs.id }
}

// ── Store ─────────────────────────────────────────────────────────────────────

final class AppliedJobsStore: ObservableObject {
    static let shared = AppliedJobsStore()
    private let key   = "applied_jobs_v1"

    @Published private(set) var appliedJobs: [AppliedJob] = []

    private init() { load() }

    // MARK: - Public API

    func markApplied(_ job: Job) {
        guard !isApplied(job) else { return }
        let record = AppliedJob(
            id:        job.id,
            title:     job.title,
            company:   job.company,
            url:       job.url,
            location:  job.location,
            appliedAt: Date(),
            status:    .applied
        )
        appliedJobs.insert(record, at: 0)
        save()
    }

    func isApplied(_ job: Job) -> Bool {
        appliedJobs.contains(where: { $0.id == job.id })
    }

    func updateStatus(id: String, status: ApplicationStatus) {
        if let idx = appliedJobs.firstIndex(where: { $0.id == id }) {
            appliedJobs[idx].status = status
            save()
        }
    }

    func remove(id: String) {
        appliedJobs.removeAll(where: { $0.id == id })
        save()
    }

    // MARK: - Analytics helpers

    var totalApplied: Int { appliedJobs.count }

    var appliedThisWeek: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return appliedJobs.filter { $0.appliedAt >= cutoff }.count
    }

    var appliedToday: Int {
        let cutoff = Calendar.current.startOfDay(for: Date())
        return appliedJobs.filter { $0.appliedAt >= cutoff }.count
    }

    func count(for status: ApplicationStatus) -> Int {
        appliedJobs.filter { $0.status == status }.count
    }

    var topCompanies: [(company: String, count: Int)] {
        var dict: [String: Int] = [:]
        appliedJobs.forEach { dict[$0.company, default: 0] += 1 }
        return dict.sorted { $0.value > $1.value }.prefix(5).map { (company: $0.key, count: $0.value) }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(appliedJobs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let arr  = try? JSONDecoder().decode([AppliedJob].self, from: data)
        else { return }
        appliedJobs = arr
    }
}
