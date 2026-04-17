import SwiftUI

// ── Filter model ──────────────────────────────────────────────────────────────

enum DatePostedFilter: String, CaseIterable, Identifiable {
    case any      = "Any time"
    case today    = "Last 24h"
    case threeDay = "Last 3 days"
    case week     = "Last week"
    case month    = "Last month"
    var id: String { rawValue }
    var daysOld: String {
        switch self {
        case .any:      return ""
        case .today:    return "1"
        case .threeDay: return "3"
        case .week:     return "7"
        case .month:    return "30"
        }
    }
}

enum ExperienceFilter: String, CaseIterable, Identifiable {
    case any    = "Any level"
    case entry  = "Entry (0–2 yrs)"
    case mid    = "Mid (2–5 yrs)"
    case senior = "Senior (5+ yrs)"
    var id: String { rawValue }
    var param: String {
        switch self {
        case .any:    return ""
        case .entry:  return "entry"
        case .mid:    return "mid"
        case .senior: return "senior"
        }
    }
}

struct JobFilters {
    var datePosted:  DatePostedFilter  = .any
    var experience:  ExperienceFilter  = .any
    var locationOverride: String       = ""   // blank = use profile location

    var isActive: Bool {
        datePosted != .any || experience != .any || !locationOverride.isEmpty
    }
    var activeCount: Int {
        (datePosted != .any ? 1 : 0) +
        (experience != .any ? 1 : 0) +
        (!locationOverride.isEmpty ? 1 : 0)
    }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

@MainActor
final class JobFeedViewModel: ObservableObject {
    @Published var jobs:          [Job]   = []
    @Published var isLoading             = false
    @Published var errorMsg: String?     = nil
    @Published var searchText            = ""
    @Published var filters               = JobFilters()

    private let baseURL = "https://jobbackend-production-3da9.up.railway.app"

    private var currentRole:     String = ""
    private var currentLocation: String = ""

    func load(role: String, location: String, freshPage: Bool = false) async {
        currentRole     = role
        currentLocation = location
        isLoading = true; errorMsg = nil; defer { isLoading = false }

        let query = searchText.isEmpty ? role : searchText
        let page  = freshPage ? String(Int.random(in: 1...5)) : "1"
        guard let url = buildURL(query: query, location: location, page: page) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(JobsResponse.self, from: data)
            if let err = resp.error, !err.isEmpty { errorMsg = err; return }
            jobs = resp.jobs
        } catch {
            errorMsg = error.localizedDescription
        }
    }

    func search() async {
        await load(role: currentRole, location: currentLocation)
    }

    func refresh() async {
        await load(role: currentRole, location: currentLocation, freshPage: true)
    }

    private func buildURL(query: String, location: String, page: String) -> URL? {
        var comps = URLComponents(string: "\(baseURL)/api/jobs")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "role",     value: query),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "per_page", value: "25"),
            URLQueryItem(name: "page",     value: page),
        ]
        if !filters.datePosted.daysOld.isEmpty {
            items.append(URLQueryItem(name: "days_old", value: filters.datePosted.daysOld))
        }
        if !filters.experience.param.isEmpty {
            items.append(URLQueryItem(name: "experience", value: filters.experience.param))
        }
        if !filters.locationOverride.isEmpty {
            items.append(URLQueryItem(name: "loc_filter", value: filters.locationOverride))
        }
        comps?.queryItems = items
        return comps?.url
    }
}
