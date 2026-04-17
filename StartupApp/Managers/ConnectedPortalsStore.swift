import Foundation

// ── Portal category ───────────────────────────────────────────────────────────

enum PortalCategory: String, CaseIterable {
    case all      = "All"
    case india    = "India"
    case global   = "Global"
    case ats      = "ATS"
    case remote   = "Remote"
}

// ── Job portal definition ─────────────────────────────────────────────────────

struct JobPortal: Identifiable, Hashable {
    let id:          String      // e.g. "linkedin"
    let name:        String
    let description: String
    let loginURL:    String      // where to log in
    let browseURL:   String      // where to land after login / browse jobs
    let homeHosts:   [String]    // URL fragments that mean "logged in"
    let icon:        String      // SF Symbol
    let color:       String      // hex
    let category:    PortalCategory
}

// ── All portals ───────────────────────────────────────────────────────────────

extension JobPortal {
    static let all: [JobPortal] = [

        // ── India ─────────────────────────────────────────────────────────────
        JobPortal(
            id: "naukri", name: "Naukri",
            description: "India's #1 job portal",
            loginURL:  "https://www.naukri.com/nlogin/login",
            browseURL: "https://www.naukri.com/jobs-in-bangalore?src=jobsearchDesk",
            homeHosts: ["www.naukri.com/mnjuser", "www.naukri.com/jobs", "www.naukri.com/"],
            icon: "doc.text.fill", color: "FF7555", category: .india
        ),
        JobPortal(
            id: "instahyre", name: "Instahyre",
            description: "Top tech & startup roles",
            loginURL:  "https://www.instahyre.com/login/",
            browseURL: "https://www.instahyre.com/candidate/opportunities/",
            homeHosts: ["www.instahyre.com/candidate", "instahyre.com/candidate"],
            icon: "bolt.fill", color: "00B386", category: .india
        ),
        JobPortal(
            id: "cutshort", name: "Cutshort",
            description: "AI-matched jobs for developers",
            loginURL:  "https://cutshort.io/login",
            browseURL: "https://cutshort.io/jobs",
            homeHosts: ["cutshort.io/jobs", "cutshort.io/dashboard", "cutshort.io/feed"],
            icon: "scissors", color: "6B4FFF", category: .india
        ),
        JobPortal(
            id: "iimjobs", name: "iimjobs",
            description: "Premium jobs for managers",
            loginURL:  "https://www.iimjobs.com/login",
            browseURL: "https://www.iimjobs.com/j/information-technology",
            homeHosts: ["www.iimjobs.com/j/", "www.iimjobs.com/dashboard"],
            icon: "building.2.fill", color: "E8006A", category: .india
        ),
        JobPortal(
            id: "foundit", name: "Foundit",
            description: "Formerly Monster India",
            loginURL:  "https://www.foundit.in/seeker/login",
            browseURL: "https://www.foundit.in/srp/results?query=software+engineer&locations=Bengaluru",
            homeHosts: ["www.foundit.in/seeker", "www.foundit.in/srp"],
            icon: "magnifyingglass.circle.fill", color: "FF4B00", category: .india
        ),
        JobPortal(
            id: "hirist", name: "Hirist",
            description: "Tech jobs curated for India",
            loginURL:  "https://www.hirist.tech/login",
            browseURL: "https://www.hirist.tech/jobs",
            homeHosts: ["www.hirist.tech/jobs", "hirist.tech/jobs", "hirist.tech/dashboard"],
            icon: "person.badge.plus.fill", color: "1E88E5", category: .india
        ),
        JobPortal(
            id: "internshala", name: "Internshala",
            description: "Internships & fresher roles",
            loginURL:  "https://internshala.com/login/student",
            browseURL: "https://internshala.com/jobs/",
            homeHosts: ["internshala.com/student/dashboard", "internshala.com/jobs"],
            icon: "graduationcap.fill", color: "00A550", category: .india
        ),
        JobPortal(
            id: "unstop", name: "Unstop",
            description: "Competitions, jobs & hiring",
            loginURL:  "https://unstop.com/auth/login",
            browseURL: "https://unstop.com/jobs",
            homeHosts: ["unstop.com/jobs", "unstop.com/opportunities"],
            icon: "trophy.fill", color: "FF6B35", category: .india
        ),

        // ── Global ────────────────────────────────────────────────────────────
        JobPortal(
            id: "linkedin", name: "LinkedIn",
            description: "The world's professional network",
            loginURL:  "https://www.linkedin.com/login",
            browseURL: "https://www.linkedin.com/jobs/search/?keywords=software+engineer&location=Bengaluru",
            homeHosts: ["www.linkedin.com/feed", "www.linkedin.com/jobs"],
            icon: "briefcase.fill", color: "0A66C2", category: .global
        ),
        JobPortal(
            id: "indeed", name: "Indeed",
            description: "Millions of jobs worldwide",
            loginURL:  "https://secure.indeed.com/auth",
            browseURL: "https://www.indeed.com/jobs?q=software+engineer&l=Bangalore",
            homeHosts: ["www.indeed.com", "secure.indeed.com/account"],
            icon: "magnifyingglass", color: "2164F3", category: .global
        ),
        JobPortal(
            id: "glassdoor", name: "Glassdoor",
            description: "Jobs + company reviews",
            loginURL:  "https://www.glassdoor.co.in/profile/login_input.htm",
            browseURL: "https://www.glassdoor.co.in/Job/bangalore-software-engineer-jobs-SRCH_IL.0,9_IC2940635_KO10,27.htm",
            homeHosts: ["www.glassdoor.co.in/Job", "glassdoor.co.in/member"],
            icon: "door.left.hand.open", color: "0CAA41", category: .global
        ),
        JobPortal(
            id: "wellfound", name: "Wellfound",
            description: "Startup jobs & equity",
            loginURL:  "https://wellfound.com/login",
            browseURL: "https://wellfound.com/jobs",
            homeHosts: ["wellfound.com/jobs", "wellfound.com/u/", "wellfound.com/talent"],
            icon: "airplane.circle.fill", color: "F7524A", category: .global
        ),

        // ── ATS Platforms ─────────────────────────────────────────────────────
        JobPortal(
            id: "greenhouse", name: "Greenhouse",
            description: "Apply at product companies",
            loginURL:  "https://boards.greenhouse.io",
            browseURL: "https://boards.greenhouse.io",
            homeHosts: ["boards.greenhouse.io", "greenhouse.io"],
            icon: "leaf.fill", color: "24B47E", category: .ats
        ),
        JobPortal(
            id: "lever", name: "Lever",
            description: "ATS used by 1000s of startups",
            loginURL:  "https://jobs.lever.co",
            browseURL: "https://jobs.lever.co",
            homeHosts: ["jobs.lever.co"],
            icon: "wrench.and.screwdriver.fill", color: "3A3A3A", category: .ats
        ),
        JobPortal(
            id: "workday", name: "Workday",
            description: "Enterprise company careers",
            loginURL:  "https://www.myworkday.com",
            browseURL: "https://www.myworkday.com",
            homeHosts: ["myworkday.com"],
            icon: "calendar.circle.fill", color: "005CB9", category: .ats
        ),

        // ── Remote ────────────────────────────────────────────────────────────
        JobPortal(
            id: "weworkremotely", name: "We Work Remotely",
            description: "100% remote jobs worldwide",
            loginURL:  "https://weworkremotely.com",
            browseURL: "https://weworkremotely.com/remote-jobs/search?term=software+engineer",
            homeHosts: ["weworkremotely.com"],
            icon: "network", color: "1E56A0", category: .remote
        ),
    ]

    static func portal(for url: String) -> JobPortal? {
        let lower = url.lowercased()
        return all.first { portal in
            portal.homeHosts.contains(where: { lower.contains($0.lowercased()) }) ||
            lower.contains(portal.id)
        }
    }
}

// ── Connected portals store ───────────────────────────────────────────────────

final class ConnectedPortalsStore: ObservableObject {
    static let shared = ConnectedPortalsStore()
    private let key   = "connected_portals_v1"

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

    var connectedCount: Int { connectedIDs.count }
    var totalCount: Int { JobPortal.all.count }

    private func save() {
        UserDefaults.standard.set(Array(connectedIDs), forKey: key)
    }
}
