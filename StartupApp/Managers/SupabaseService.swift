import Foundation

// Supabase REST client — no external SDK needed.
final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    private let url     = "https://btmofwguupglwmkxvdjr.supabase.co"
    private let anonKey = "sb_publishable_6ZvX9-YUtcVREVA_KbjQqw_HyIle67z"

    // ── Codable model matching the DB schema ──────────────────────────────────
    struct ProfileRow: Codable {
        var id:         String?
        var user_id:    String
        var name:       String
        var email:      String
        var phone:      String
        var job_role:   String
        var created_at: String?
        var updated_at: String?
    }

    // ── Fetch profile for a given user_id ─────────────────────────────────────
    func fetchProfile(userId: String) async throws -> ProfileRow? {
        var req = request("/rest/v1/profiles?user_id=eq.\(userId)&limit=1")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateResponse(resp, data: data)

        let rows = try JSONDecoder().decode([ProfileRow].self, from: data)
        return rows.first
    }

    // ── Upsert (insert or update) profile ─────────────────────────────────────
    func upsertProfile(_ row: ProfileRow) async throws -> ProfileRow {
        var req = request("/rest/v1/profiles")
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        // Upsert on user_id conflict
        req.setValue("resolution=merge-duplicates,on_conflict=user_id", forHTTPHeaderField: "Prefer")

        req.httpBody = try JSONEncoder().encode(row)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateResponse(resp, data: data)

        let rows = try JSONDecoder().decode([ProfileRow].self, from: data)
        guard let saved = rows.first else { throw SupabaseError.noData }
        return saved
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private func request(_ path: String) -> URLRequest {
        var req = URLRequest(url: URL(string: url + path)!)
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 15
        return req
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw SupabaseError.http(http.statusCode, body)
        }
    }

    enum SupabaseError: LocalizedError {
        case invalidResponse
        case noData
        case http(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:    return "Invalid server response"
            case .noData:             return "No data returned"
            case .http(let code, let body): return "Server error \(code): \(body)"
            }
        }
    }
}
