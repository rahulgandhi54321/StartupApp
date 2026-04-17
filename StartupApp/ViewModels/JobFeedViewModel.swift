import SwiftUI

@MainActor
final class JobFeedViewModel: ObservableObject {
    @Published var jobs:       [Job]   = []
    @Published var isLoading          = false
    @Published var errorMsg: String?  = nil
    @Published var searchText         = ""

    // ── Replace with your Railway/deployed URL once live ─────────────────────
    // For local testing use your Mac's LAN IP, e.g. http://192.168.1.5:8080
    private let baseURL = "https://jobhunter-backend.up.railway.app"

    private var currentRole:     String = ""
    private var currentLocation: String = ""

    func load(role: String, location: String) async {
        currentRole     = role
        currentLocation = location
        isLoading = true; errorMsg = nil; defer { isLoading = false }

        let query = searchText.isEmpty ? role : searchText
        guard let url = buildURL(query: query, location: location) else { return }
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

    private func buildURL(query: String, location: String) -> URL? {
        var comps = URLComponents(string: "\(baseURL)/api/jobs")
        comps?.queryItems = [
            URLQueryItem(name: "role",     value: query),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "per_page", value: "25"),
        ]
        return comps?.url
    }
}
