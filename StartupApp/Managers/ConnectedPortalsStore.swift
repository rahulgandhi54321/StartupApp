import Foundation

struct JobPortal: Identifiable, Hashable {
    let id:          String      // e.g. "linkedin"
    let name:        String
    let loginURL:    String
    let homeHosts:   [String]    // URL hosts that mean "logged in"
    let icon:        String      // SF Symbol
    let color:       String      // hex
}

extension JobPortal {
    static let all: [JobPortal] = [
        JobPortal(id: "linkedin",    name: "LinkedIn",    loginURL: "https://www.linkedin.com/login",
                  homeHosts: ["www.linkedin.com/feed", "www.linkedin.com/jobs"],
                  icon: "briefcase.fill",   color: "0A66C2"),
        JobPortal(id: "naukri",      name: "Naukri",      loginURL: "https://www.naukri.com/nlogin/login",
                  homeHosts: ["www.naukri.com"],
                  icon: "doc.text.fill",    color: "FF7555"),
        JobPortal(id: "indeed",      name: "Indeed",      loginURL: "https://secure.indeed.com/auth",
                  homeHosts: ["www.indeed.com"],
                  icon: "magnifyingglass",  color: "2164F3"),
        JobPortal(id: "internshala", name: "Internshala", loginURL: "https://internshala.com/login",
                  homeHosts: ["internshala.com/student/dashboard"],
                  icon: "graduationcap.fill", color: "00A550"),
    ]

    static func portal(for url: String) -> JobPortal? {
        let lower = url.lowercased()
        return all.first { portal in
            portal.homeHosts.contains(where: { lower.contains($0.lowercased()) }) ||
            lower.contains(portal.id)
        }
    }
}

final class ConnectedPortalsStore: ObservableObject {
    static let shared = ConnectedPortalsStore()
    private let key = "connected_portals_v1"

    @Published private(set) var connectedIDs: Set<String> = []

    private init() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            connectedIDs = Set(arr)
        }
    }

    func isConnected(_ portal: JobPortal) -> Bool { connectedIDs.contains(portal.id) }

    func markConnected(_ portal: JobPortal) {
        connectedIDs.insert(portal.id)
        save()
    }

    func disconnect(_ portal: JobPortal) {
        connectedIDs.remove(portal.id)
        save()
    }

    private func save() {
        UserDefaults.standard.set(Array(connectedIDs), forKey: key)
    }
}
