import Foundation

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    private let baseURL = "https://btmofwguupglwmkxvdjr.supabase.co"
    private let anonKey = "sb_publishable_6ZvX9-YUtcVREVA_KbjQqw_HyIle67z"

    // ── MARK: Models ──────────────────────────────────────────────────────────

    struct ProfileRow: Codable {
        var id:         String?
        var user_id:    String
        var name:       String
        var email:      String
        var phone:      String
        var job_role:   String
        var gender:     String
        var created_at: String?
        var updated_at: String?
    }

    struct JobPrefRow: Codable {
        var id:              String?
        var user_id:         String
        var resume_url:      String
        var current_ctc:     String
        var expected_ctc:    String
        var location:        String
        var notice_period:   String
        var experience:      String
        var linkedin_url:    String
        var skills:          String
        var created_at:      String?
        var updated_at:      String?
    }

    // ── MARK: Profile ─────────────────────────────────────────────────────────

    func fetchProfile(userId: String) async throws -> ProfileRow? {
        var req = request("/rest/v1/profiles?user_id=eq.\(userId)&limit=1")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return try JSONDecoder().decode([ProfileRow].self, from: data).first
    }

    func upsertProfile(_ row: ProfileRow) async throws -> ProfileRow {
        var req = request("/rest/v1/profiles?on_conflict=user_id")
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        var p = row; p.id = nil; p.created_at = nil; p.updated_at = nil
        req.httpBody = try JSONEncoder().encode(p)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return try JSONDecoder().decode([ProfileRow].self, from: data).first ?? row
    }

    // ── MARK: Job Preferences ─────────────────────────────────────────────────

    func fetchJobPref(userId: String) async throws -> JobPrefRow? {
        var req = request("/rest/v1/job_preferences?user_id=eq.\(userId)&limit=1")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return try JSONDecoder().decode([JobPrefRow].self, from: data).first
    }

    func upsertJobPref(_ row: JobPrefRow) async throws -> JobPrefRow {
        var req = request("/rest/v1/job_preferences?on_conflict=user_id")
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        var p = row; p.id = nil; p.created_at = nil; p.updated_at = nil
        req.httpBody = try JSONEncoder().encode(p)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data)
        return try JSONDecoder().decode([JobPrefRow].self, from: data).first ?? row
    }

    // ── MARK: Resume Upload ───────────────────────────────────────────────────

    func uploadResume(userId: String, pdfData: Data) async throws -> String {
        let fileName = "\(userId)/resume.pdf"
        let encoded  = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        var req = request("/storage/v1/object/resumes/\(encoded)")
        req.httpMethod = "POST"
        req.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")
        req.httpBody = pdfData
        let (_, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: Data())
        // Return public URL
        return "\(baseURL)/storage/v1/object/public/resumes/\(encoded)"
    }

    // ── MARK: Helpers ─────────────────────────────────────────────────────────

    private func request(_ path: String) -> URLRequest {
        var req = URLRequest(url: URL(string: baseURL + path)!)
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20
        return req
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw Err.invalid }
        guard (200...299).contains(http.statusCode) else {
            throw Err.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    enum Err: LocalizedError {
        case invalid, noData, http(Int, String)
        var errorDescription: String? {
            switch self {
            case .invalid:          return "Invalid response"
            case .noData:           return "No data"
            case .http(let c, let b): return "Server error \(c): \(b)"
            }
        }
    }
}
