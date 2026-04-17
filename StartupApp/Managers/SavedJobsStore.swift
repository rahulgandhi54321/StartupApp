import Foundation

final class SavedJobsStore: ObservableObject {
    static let shared = SavedJobsStore()
    private let key = "saved_jobs_v1"

    @Published private(set) var savedJobs: [Job] = []

    private init() { load() }

    func isSaved(_ job: Job) -> Bool { savedJobs.contains { $0.id == job.id } }

    func toggle(_ job: Job) {
        if isSaved(job) {
            savedJobs.removeAll { $0.id == job.id }
        } else {
            savedJobs.insert(job, at: 0)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(savedJobs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let jobs = try? JSONDecoder().decode([Job].self, from: data) else { return }
        savedJobs = jobs
    }
}
