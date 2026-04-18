import SwiftUI
import SafariServices

// ══════════════════════════════════════════════════════════════════════════════
// WHY SFSafariViewController INSTEAD OF WKWebView FOR MAJOR PORTALS
// ══════════════════════════════════════════════════════════════════════════════
//
// WKWebView fails on LinkedIn / Indeed / Naukri / Glassdoor because:
//
//  1. SEPARATE COOKIE JAR — WKWebView has its own isolated storage, completely
//     disconnected from Safari. Even WKWebsiteDataStore.default() is NOT the
//     same store as Safari. The user is never "already logged in".
//
//  2. UA FINGERPRINTING — Platforms read navigator.userAgent and window.webkit
//     internals. They detect the embedded view and hard-block it, showing
//     "unauthorized access" even with a spoofed UA string.
//
//  3. OAUTH BLOCKED — Apple's own App Review guidelines (§4.7) and RFC 8252
//     forbid using embedded web views for OAuth. Google/LinkedIn SSO explicitly
//     reject WKWebView. Their servers check the referrer & JS environment.
//
//  4. MISSING BROWSER APIs — WKWebView lacks service workers, certain
//     storage APIs, and browser-specific objects platforms rely on.
//
//  SFSafariViewController solves all four:
//  • Shares the EXACT same cookie store as Safari.app — login persists.
//  • Identical User-Agent and JS environment as Safari — undetectable.
//  • Accepted by every OAuth provider (Apple requirement since iOS 9).
//  • Full browser feature set including service workers.
//
//  Trade-off: No JavaScript injection → use "Quick Copy" clipboard helper
//  so users can paste their profile data into any form in seconds.
//
//  WKWebView is still used for ATS boards (Greenhouse, Lever, Workday)
//  that don't block it and benefit most from JS auto-fill.
// ══════════════════════════════════════════════════════════════════════════════

// MARK: - SafariView (UIViewControllerRepresentable)

struct SafariView: UIViewControllerRepresentable {
    let url:       URL
    var tintColor: Color   = Color(hex: "6C63FF")
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        cfg.barCollapsingEnabled    = true

        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.preferredBarTintColor     = .systemBackground
        vc.preferredControlTintColor = UIColor(tintColor)
        vc.dismissButtonStyle        = .close
        vc.delegate                  = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var parent: SafariView
        init(_ p: SafariView) { parent = p }
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.onDismiss?()
        }
    }
}

// MARK: - Apply Method Router

/// Decides whether a URL should open in SFSafariViewController or WKWebView.
/// Rule: any platform known to detect/block WKWebView → Safari.
///       Small ATS boards (Greenhouse, Lever) where JS auto-fill works → WebView.
enum ApplyMethod {
    case safari      // SFSafariViewController — shared cookies, real Safari UA
    case webView     // WKWebView + auto-fill JS
}

struct JobApplyRouter {
    // Hosts that actively block WKWebView or require shared-Safari sessions
    static let safariOnlyPatterns: [String] = [
        "linkedin.com",
        "indeed.com",
        "naukri.com",
        "glassdoor.",
        "wellfound.com",
        "angel.co",
        "cutshort.io",
        "iimjobs.com",
        "foundit.in",
        "hirist.",
        "instahyre.com",
        "unstop.com",
        "internshala.com",
        "productfolks.com",
        "shine.com",
        "monster.",
        "angellist.com",
    ]

    static func method(for urlString: String) -> ApplyMethod {
        guard let url = URL(string: urlString) else { return .safari }
        let host = (url.host ?? "").lowercased().replacingOccurrences(of: "www.", with: "")
        return safariOnlyPatterns.contains(where: { host.contains($0) }) ? .safari : .webView
    }
}

// MARK: - Safari Connection Pre-warmer

/// Call at app launch (or when the job list loads) to pre-warm TLS/TCP
/// connections to the most-visited job sites — Safari opens instantly.
@MainActor
final class SafariPrewarmer {
    static let shared = SafariPrewarmer()
    private var token: AnyObject?   // SFSafariViewController.PrewarmingToken

    func prewarm(urlStrings: [String] = [
        "https://www.linkedin.com",
        "https://www.naukri.com",
        "https://www.indeed.com",
        "https://wellfound.com",
        "https://cutshort.io",
        "https://www.glassdoor.co.in",
    ]) {
        guard #available(iOS 15, *) else { return }
        let urls = urlStrings.compactMap { URL(string: $0) }
        token = SFSafariViewController.prewarmConnections(to: urls) as AnyObject
    }
}

// MARK: - QuickFillSheet
// Shown before opening the apply URL.
//  • Safari path  → display clipboard chips so user can paste into any form
//  • WebView path → opens WKWebView with auto-fill JS
// After the browser closes, prompts "Did you apply?" → Mark as Applied.

struct QuickFillSheet: View {
    let job:     Job
    let profile: SupabaseService.ProfileRow?
    let jobPref: SupabaseService.JobPrefRow?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appliedStore = AppliedJobsStore.shared

    @State private var showSafari          = false
    @State private var showWebView         = false
    @State private var returnedFromApply   = false
    @State private var isApplied           = false
    @State private var copiedField: String? = nil

    private var applyMethod: ApplyMethod { JobApplyRouter.method(for: job.url) }

    private var userData: [String: String] {
        buildUserData(profile: profile, jobPref: jobPref,
                      jobTitle: job.title, company: job.company)
    }

    private var quickFields: [(icon: String, label: String, value: String)] {
        [
            ("person.fill",                  "Full Name",     userData["name"]         ?? ""),
            ("envelope.fill",                "Email",         userData["email"]        ?? ""),
            ("phone.fill",                   "Phone",         userData["phone"]        ?? ""),
            ("link",                         "LinkedIn URL",  userData["linkedin"]     ?? ""),
            ("briefcase.fill",               "Experience",    "\(userData["experience"] ?? "") yrs"),
            ("indianrupeesign.circle.fill",  "Current CTC",  userData["currentCTC"]   ?? ""),
            ("indianrupeesign.circle.fill",  "Expected CTC", userData["expectedCTC"]  ?? ""),
            ("calendar.badge.clock",         "Notice Period", userData["noticePeriod"] ?? ""),
            ("mappin.fill",                  "Location",      userData["location"]     ?? ""),
            ("person.text.rectangle.fill",   "Current Role",  userData["role"]         ?? ""),
            ("doc.text.fill",                "Resume URL",    userData["resumeURL"]    ?? ""),
        ].filter { !$0.value.isEmpty && $0.value != " yrs" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        jobHeader
                        if returnedFromApply { postApplyCard }
                        else {
                            methodBadgeRow
                            if applyMethod == .safari { quickFillCard }
                            actionButtons
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Apply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // ── Safari cover ──────────────────────────────────────────────────────
        .fullScreenCover(isPresented: $showSafari, onDismiss: {
            withAnimation(.spring(response: 0.4)) { returnedFromApply = true }
        }) {
            if let url = URL(string: job.url) {
                SafariView(url: url, tintColor: Color(hex: "6C63FF")) { showSafari = false }
                    .ignoresSafeArea()
            }
        }
        // ── WKWebView cover ───────────────────────────────────────────────────
        .fullScreenCover(isPresented: $showWebView, onDismiss: {
            withAnimation(.spring(response: 0.4)) { returnedFromApply = true }
        }) {
            NavigationStack {
                JobWebView(job: job, profile: profile, jobPref: jobPref)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { showWebView = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20)).foregroundColor(.secondary)
                            }
                        }
                    }
            }
        }
        .onAppear { isApplied = appliedStore.isApplied(job) }
    }

    // ── Job header ─────────────────────────────────────────────────────────────
    private var jobHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                Text(String(job.company.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(job.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black).lineLimit(2)
                Text(job.company)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color(hex: "6C63FF"))
                if !job.location.isEmpty {
                    Label(job.location, systemImage: "location.fill")
                        .font(.system(size: 11, design: .rounded)).foregroundColor(.secondary)
                }
            }
            Spacer()
            if isApplied {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20)).foregroundColor(Color(hex: "10B981"))
            }
        }
        .padding(16).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // ── Method badge ───────────────────────────────────────────────────────────
    private var methodBadgeRow: some View {
        let isSafari = applyMethod == .safari
        return HStack(spacing: 10) {
            Image(systemName: isSafari ? "safari.fill" : "wand.and.stars")
                .font(.system(size: 16))
                .foregroundColor(isSafari ? Color(hex: "0A66C2") : Color(hex: "10B981"))
            VStack(alignment: .leading, spacing: 3) {
                Text(isSafari ? "Opens in Safari" : "Opens with Auto-fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(isSafari
                     ? "Uses your existing Safari login — no extra sign-in needed"
                     : "Form fields will be auto-filled from your profile")
                    .font(.system(size: 11, design: .rounded)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background((isSafari ? Color(hex: "0A66C2") : Color(hex: "10B981")).opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke((isSafari ? Color(hex: "0A66C2") : Color(hex: "10B981")).opacity(0.15), lineWidth: 1))
    }

    // ── Quick-copy clipboard card ───────────────────────────────────────────────
    private var quickFillCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 13)).foregroundColor(Color(hex: "6C63FF"))
                Text("Quick Copy")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text("Tap any field to copy → paste in the form")
                    .font(.system(size: 10, design: .rounded)).foregroundColor(.secondary)
            }
            FlowLayout(spacing: 8) {
                ForEach(quickFields, id: \.label) { f in
                    QuickCopyChip(icon: f.icon, label: f.label, value: f.value,
                                  isCopied: copiedField == f.label) {
                        UIPasteboard.general.string = f.value
                        withAnimation(.spring(response: 0.25)) { copiedField = f.label }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { copiedField = nil }
                        }
                    }
                }
            }
        }
        .padding(16).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // ── Action buttons ─────────────────────────────────────────────────────────
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Primary CTA
            Button {
                applyMethod == .safari ? (showSafari = true) : (showWebView = true)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: applyMethod == .safari ? "safari.fill" : "wand.and.stars")
                    Text(applyMethod == .safari ? "Open in Safari & Apply" : "Open with Auto-fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(LinearGradient(
                    colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                    startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "6C63FF").opacity(0.28), radius: 8, y: 4)
            }

            // Secondary: always offer the other method
            Button {
                applyMethod == .safari ? (showWebView = true) : (showSafari = true)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: applyMethod == .safari ? "wand.and.stars" : "safari.fill")
                        .font(.system(size: 12))
                    Text(applyMethod == .safari
                         ? "Try Auto-fill instead (may be blocked on this site)"
                         : "Open in Safari instead")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary).frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if isApplied {
                appliedPill
            } else {
                // Mark applied without opening
                Button {
                    appliedStore.markApplied(job)
                    withAnimation { isApplied = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark").font(.system(size: 13))
                        Text("Already applied? Mark as Applied")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "6C63FF")).frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(Color(hex: "6C63FF").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // ── Post-apply "Did you apply?" card ──────────────────────────────────────
    private var postApplyCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 30)).foregroundColor(Color(hex: "F59E0B"))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Did you apply?")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Track it and we'll manage your pipeline.")
                        .font(.system(size: 12, design: .rounded)).foregroundColor(.secondary)
                }
            }
            .padding(16).background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

            if isApplied {
                appliedPill
            } else {
                HStack(spacing: 10) {
                    Button {
                        appliedStore.markApplied(job)
                        withAnimation(.spring(response: 0.4)) { isApplied = true }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Yes, I Applied!")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color(hex: "10B981"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 6, y: 3)
                    }

                    Button {
                        // Let them try again
                        withAnimation { returnedFromApply = false }
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    private var appliedPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "10B981"))
            Text("Application Tracked ✓")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundColor(Color(hex: "10B981")).frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color(hex: "10B981").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - QuickCopyChip

struct QuickCopyChip: View {
    let icon:     String
    let label:    String
    let value:    String
    let isCopied: Bool
    let onTap:    () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 11))
                    .foregroundColor(isCopied ? Color(hex: "10B981") : Color(hex: "6C63FF"))
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(isCopied ? "Copied!" : value)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(isCopied ? Color(hex: "10B981") : .black)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(isCopied
                        ? Color(hex: "10B981").opacity(0.1)
                        : Color(hex: "6C63FF").opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                isCopied
                    ? Color(hex: "10B981").opacity(0.3)
                    : Color(hex: "6C63FF").opacity(0.15),
                lineWidth: 1))
            .animation(.spring(response: 0.25), value: isCopied)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout  (chips wrap to next line automatically)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var y: CGFloat = 0, x: CGFloat = 0, rowH: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > width, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing; x = bounds.minX; rowH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}
