import Foundation

struct Job: Identifiable, Codable, Equatable {
    var id:          String
    var title:       String
    var company:     String
    var location:    String
    var description: String
    var url:         String
    var salary:      String
    var posted_at:   String
    var category:    String

    /// Infer experience level from title keywords
    var inferredExperience: ExperienceLevel {
        let t = title.lowercased()
        if t.contains("senior") || t.contains("lead") || t.contains("principal") ||
           t.contains("staff")  || t.contains("director") || t.contains("vp") { return .senior }
        if t.contains("junior") || t.contains("entry") || t.contains("graduate") ||
           t.contains("fresher") || t.contains("intern") || t.contains("trainee") { return .entry }
        return .mid
    }

    enum ExperienceLevel: String {
        case entry  = "Entry (0–2 yrs)"
        case mid    = "Mid (2–5 yrs)"
        case senior = "Senior (5+ yrs)"
    }
}

struct JobsResponse: Codable {
    var jobs:    [Job]
    var total:   Int
    var page:    Int
    var keyword: String?
    var error:   String?
}
