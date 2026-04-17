import Foundation

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    private let baseURL = "https://btmofwguupglwmkxvdjr.supabase.co"
    private let anonKey = "sb_publishable_6ZvX9-YUtcVREVA_KbjQqw_HyIle67z"

    // ── Models — every field has a safe default so decoding never crashes ─────

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

        init(id: String? = nil, user_id: String, name: String, email: String,
             phone: String, job_role: String, gender: String) {
            self.id = id; self.user_id = user_id; self.name = name
            self.email = email; self.phone = phone
            self.job_role = job_role; self.gender = gender
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id         = try c.decodeIfPresent(String.self, forKey: .id)
            user_id    = (try? c.decodeIfPresent(String.self, forKey: .user_id))  ?? ""
            name       = (try? c.decodeIfPresent(String.self, forKey: .name))     ?? ""
            email      = (try? c.decodeIfPresent(String.self, forKey: .email))    ?? ""
            phone      = (try? c.decodeIfPresent(String.self, forKey: .phone))    ?? ""
            job_role   = (try? c.decodeIfPresent(String.self, forKey: .job_role)) ?? ""
            gender     = (try? c.decodeIfPresent(String.self, forKey: .gender))   ?? ""
            created_at = try? c.decodeIfPresent(String.self, forKey: .created_at)
            updated_at = try? c.decodeIfPresent(String.self, forKey: .updated_at)
        }
    }

    struct JobPrefRow: Codable {
        var id:            String?
        var user_id:       String
        var resume_url:    String
        var current_ctc:   String
        var expected_ctc:  String
        var location:      String
        var notice_period: String
        var experience:    String
        var linkedin_url:  String
        var skills:        String
        var created_at:    String?
        var updated_at:    String?

        init(id: String? = nil, user_id: String, resume_url: String = "",
             current_ctc: String = "", expected_ctc: String = "", location: String = "",
             notice_period: String = "", experience: String = "",
             linkedin_url: String = "", skills: String = "") {
            self.id = id; self.user_id = user_id; self.resume_url = resume_url
            self.current_ctc = current_ctc; self.expected_ctc = expected_ctc
            self.location = location; self.notice_period = notice_period
            self.experience = experience; self.linkedin_url = linkedin_url
            self.skills = skills
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id            = try c.decodeIfPresent(String.self, forKey: .id)
            user_id       = (try? c.decodeIfPresent(String.self, forKey: .user_id))       ?? ""
            resume_url    = (try? c.decodeIfPresent(String.self, forKey: .resume_url))    ?? ""
            current_ctc   = (try? c.decodeIfPresent(String.self, forKey: .current_ctc))   ?? ""
            expected_ctc  = (try? c.decodeIfPresent(String.self, forKey: .expected_ctc))  ?? ""
            location      = (try? c.decodeIfPresent(String.self, forKey: .location))      ?? ""
            notice_period = (try? c.decodeIfPresent(String.self, forKey: .notice_period)) ?? ""
            experience    = (try? c.decodeIfPresent(String.self, forKey: .experience))    ?? ""
            linkedin_url  = (try? c.decodeIfPresent(String.self, forKey: .linkedin_url))  ?? ""
            skills        = (try? c.decodeIfPresent(String.self, forKey: .skills))        ?? ""
            created_at    = try? c.decodeIfPresent(String.self, forKey: .created_at)
            updated_at    = try? c.decodeIfPresent(String.self, forKey: .updated_at)
        }
    }

    // ── Profile ───────────────────────────────────────────────────────────────

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
        return (try? JSONDecoder().decode([ProfileRow].self, from: data).first) ?? row
    }

    // ── Job Preferences ───────────────────────────────────────────────────────

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
        return (try? JSONDecoder().decode([JobPrefRow].self, from: data).first) ?? row
    }

    // ── Resume Upload ─────────────────────────────────────────────────────────

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
        return "\(baseURL)/storage/v1/object/public/resumes/\(encoded)"
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

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
        case invalid, http(Int, String)
        var errorDescription: String? {
            switch self {
            case .invalid: return "Invalid response"
            case .http(let c, let b): return "Server error \(c): \(b)"
            }
        }
    }
}
