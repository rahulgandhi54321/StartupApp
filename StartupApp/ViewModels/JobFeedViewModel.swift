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
    @Published var jobs:           [Job]   = []
    @Published var isLoading              = false
    @Published var isLoadingMore          = false
    @Published var errorMsg: String?      = nil
    @Published var searchText             = ""
    @Published var filters                = JobFilters()
    @Published var totalAvailable         = 0

    private let baseURL = "https://jobbackend-production-3da9.up.railway.app"
    private let perPage = 50                      // Adzuna max

    private var currentRole:     String = ""
    private var currentLocation: String = ""
    private var currentPage             = 1
    private var seenIDs:    Set<String> = []      // deduplicate across pages

    // Initial load or filter/search change — reset everything
    func load(role: String, location: String) async {
        currentRole     = role
        currentLocation = location
        currentPage     = 1
        seenIDs         = []
        isLoading = true; errorMsg = nil; defer { isLoading = false }
        if let fetched = await fetch(page: currentPage) {
            let filtered   = applyClientFilters(fetched.jobs)
            jobs           = filtered
            totalAvailable = fetched.total
            seenIDs        = Set(fetched.jobs.map(\.id))
        }
    }

    // Pull-to-refresh — next page, fresh batch
    func refresh() async {
        currentPage += 1
        isLoading = true; errorMsg = nil; defer { isLoading = false }
        if let fetched = await fetch(page: currentPage) {
            let fresh = fetched.jobs.filter { !seenIDs.contains($0.id) }
            fresh.forEach { seenIDs.insert($0.id) }
            let source     = fresh.isEmpty ? fetched.jobs : fresh
            jobs           = applyClientFilters(source)
            totalAvailable = fetched.total
        }
    }

    // Load more — append next page
    func loadMore() async {
        guard !isLoadingMore && !isLoading else { return }
        currentPage += 1
        isLoadingMore = true; defer { isLoadingMore = false }
        if let fetched = await fetch(page: currentPage) {
            let fresh = fetched.jobs.filter { !seenIDs.contains($0.id) }
            fresh.forEach { seenIDs.insert($0.id) }
            jobs          += applyClientFilters(fresh)
            totalAvailable = fetched.total
        }
    }

    func search() async {
        await load(role: currentRole, location: currentLocation)
    }

    // ── Client-side experience filter (Adzuna has no native exp param) ─────────
    private func applyClientFilters(_ input: [Job]) -> [Job] {
        guard filters.experience != .any else { return input }
        return input.filter { job in
            switch filters.experience {
            case .any:    return true
            case .entry:  return job.inferredExperience == .entry
            case .mid:    return job.inferredExperience == .mid
            case .senior: return job.inferredExperience == .senior
            }
        }
    }

    // ── Private fetch ──────────────────────────────────────────────────────────
    private func fetch(page: Int) async -> JobsResponse? {
        let query = searchText.isEmpty ? currentRole : searchText
        guard let url = buildURL(query: query, location: currentLocation, page: page) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(JobsResponse.self, from: data)
            if let err = resp.error, !err.isEmpty { errorMsg = err; return nil }
            return resp
        } catch {
            errorMsg = error.localizedDescription
            return nil
        }
    }

    private func buildURL(query: String, location: String, page: Int) -> URL? {
        var comps = URLComponents(string: "\(baseURL)/api/jobs")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "role",     value: query),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page",     value: String(page)),
        ]
        // Date posted — passed to backend (Adzuna max_days_old)
        if !filters.datePosted.daysOld.isEmpty {
            items.append(URLQueryItem(name: "days_old", value: filters.datePosted.daysOld))
        }
        // Experience — handled client-side via applyClientFilters()
        // Location override — user typed a custom city
        if !filters.locationOverride.isEmpty {
            items.append(URLQueryItem(name: "loc_filter", value: filters.locationOverride))
        }
        comps?.queryItems = items
        return comps?.url
    }
}
