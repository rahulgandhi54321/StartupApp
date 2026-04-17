import SwiftUI
import WebKit

// ── Job Portals Tab ───────────────────────────────────────────────────────────

struct JobPortalsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject private var store = ConnectedPortalsStore.shared

    @State private var selectedCategory: PortalCategory = .all
    @State private var selectedPortal: JobPortal? = nil          // for login
    @State private var browsingPortal: JobPortal? = nil          // for browsing

    private var filtered: [JobPortal] {
        selectedCategory == .all
            ? JobPortal.all
            : JobPortal.all.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        statsHeader
                        categoryChips
                        portalsGrid
                        Spacer(minLength: 30)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Job Portals")
            .navigationBarTitleDisplayMode(.large)
            // Login sheet
            .sheet(item: $selectedPortal) { portal in
                NavigationStack {
                    PortalLoginView(portal: portal)
                }
            }
            // Browse portal full-screen
            .fullScreenCover(item: $browsingPortal) { portal in
                PortalBrowserView(
                    portal:  portal,
                    profile: authVM.remoteProfile,
                    jobPref: authVM.remoteJobPref
                )
            }
        }
    }

    // ── Stats header ───────────────────────────────────────────────────────────
    private var statsHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.connectedCount) of \(store.totalCount) connected")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                Text("Tap a portal to browse jobs. Log in once to stay connected.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color(hex: "E8E8FF"), lineWidth: 5)
                    .frame(width: 58, height: 58)
                Circle()
                    .trim(from: 0, to: store.totalCount > 0
                          ? CGFloat(store.connectedCount) / CGFloat(store.totalCount) : 0)
                    .stroke(Color(hex: "6C63FF"), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 58, height: 58)
                    .animation(.spring(), value: store.connectedCount)
                Text("\(store.connectedCount)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "6C63FF"))
            }
        }
        .padding(20).background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // ── Category chips ─────────────────────────────────────────────────────────
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PortalCategory.allCases, id: \.self) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
                    } label: {
                        Text(cat.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedCategory == cat ? .white : Color(hex: "6C63FF"))
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(
                                selectedCategory == cat
                                    ? AnyShapeStyle(Color(hex: "6C63FF"))
                                    : AnyShapeStyle(Color(hex: "6C63FF").opacity(0.1))
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // ── Portals grid ───────────────────────────────────────────────────────────
    private var portalsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                  spacing: 14) {
            ForEach(filtered) { portal in
                PortalCard(
                    portal:    portal,
                    connected: store.isConnected(portal),
                    onConnect: { selectedPortal = portal },
                    onBrowse:  { browsingPortal = portal },
                    onDisconnect: { store.disconnect(portal) }
                )
            }
        }
    }
}

// ── Portal card ───────────────────────────────────────────────────────────────

struct PortalCard: View {
    let portal:       JobPortal
    let connected:    Bool
    let onConnect:    () -> Void
    let onBrowse:     () -> Void
    let onDisconnect: () -> Void

    @State private var showMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: portal.color).opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: portal.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: portal.color))
                }
                Spacer()
                // Connected badge
                if connected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "10B981"))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(portal.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                Text(portal.description)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Category tag
            Text(portal.category.rawValue.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: portal.color))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(hex: portal.color).opacity(0.1))
                .clipShape(Capsule())

            Spacer(minLength: 0)

            // Action button
            if connected {
                Button(action: onBrowse) {
                    Text("Browse Jobs →")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(Color(hex: portal.color))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .contextMenu {
                    Button { onBrowse() } label: {
                        Label("Browse Jobs", systemImage: "safari")
                    }
                    Button(role: .destructive) { onDisconnect() } label: {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                }
            } else {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: portal.color))
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(Color(hex: portal.color).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: portal.color).opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color(hex: portal.color).opacity(connected ? 0.12 : 0.04),
                radius: connected ? 10 : 6, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(connected ? Color(hex: portal.color).opacity(0.2) : Color.clear, lineWidth: 1.5)
        )
    }
}

// ── Portal Browser View ───────────────────────────────────────────────────────
// Full in-app browser — persistent cookies, auto-fill everywhere, mark applied

struct PortalBrowserView: View {
    let portal:  JobPortal
    let profile: SupabaseService.ProfileRow?
    let jobPref: SupabaseService.JobPrefRow?

    @StateObject private var ctrl       = PortalBrowserController()
    @ObservedObject private var cStore  = ConnectedPortalsStore.shared
    @ObservedObject private var aStore  = AppliedJobsStore.shared

    @State private var showReview          = false
    @State private var filledFields: [(label: String, value: String)] = []
    @State private var autoFillState: AutoFillBrowserState = .idle
    @State private var showAppliedBanner   = false
    @State private var showAutoLoginBanner = false
    @State private var isMarkedApplied     = false
    @State private var barExpanded         = false
    @Environment(\.dismiss) private var dismiss

    enum AutoFillBrowserState { case idle, filling, done }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // WebView
                PortalBrowserRepresentable(
                    startURL:     portal.browseURL,
                    controller:   ctrl,
                    userDataJSON: buildUserDataJSON(),
                    profileEmail: profile?.email ?? ""
                )
                .ignoresSafeArea(edges: .bottom)

                // Progress bar
                if ctrl.progress < 1.0 {
                    VStack {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color(hex: portal.color))
                                .frame(width: geo.size.width * ctrl.progress, height: 3)
                                .animation(.linear(duration: 0.1), value: ctrl.progress)
                        }.frame(height: 3)
                        Spacer()
                    }
                }

                // Banners
                if showAppliedBanner || showAutoLoginBanner {
                    VStack {
                        if showAutoLoginBanner {
                            BannerView(icon: "person.crop.circle.badge.checkmark",
                                       color: portal.color, text: "Auto-login attempted on \(ctrl.currentDomain)")
                        }
                        if showAppliedBanner {
                            BannerView(icon: "bookmark.fill", color: "10B981", text: "Marked as Applied ✓")
                        }
                        Spacer()
                    }
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Bottom bar
                bottomBar
            }
            .navigationTitle(ctrl.pageTitle.isEmpty ? portal.name : ctrl.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showReview) {
                PortalAutoFillReview(
                    portalName:   portal.name,
                    filledFields: filledFields,
                    onSubmit:     runSubmit,
                    onDismiss:    { showReview = false }
                )
            }
        }
        .onReceive(ctrl.$currentURL) { url in
            guard let url = url else { return }
            let isLoggedIn = portal.homeHosts.contains(where: {
                url.lowercased().contains($0.lowercased())
            })
            if isLoggedIn && !cStore.isConnected(portal) {
                cStore.markConnected(portal)
            }
        }
    }

    // ── Floating pill bottom bar (same collapse pattern as JobWebView) ──────────
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                if barExpanded {
                    HStack(spacing: 10) {
                        // Auto-fill
                        Button {
                            withAnimation(.spring(response: 0.3)) { barExpanded = false }
                            if autoFillState == .done { showReview = true }
                            else { runAutoFill() }
                        } label: {
                            HStack(spacing: 6) {
                                if autoFillState == .filling {
                                    ProgressView().tint(.white).scaleEffect(0.75)
                                } else {
                                    Image(systemName: autoFillState == .done
                                          ? "checkmark.circle.fill" : "wand.and.stars")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                Text(autoFillState == .filling ? "Filling…" :
                                     autoFillState == .done    ? "Review" : "Auto-fill")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(
                                autoFillState == .done
                                    ? AnyShapeStyle(Color(hex: "10B981"))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color(hex: portal.color), Color(hex: "A78BFA")],
                                        startPoint: .leading, endPoint: .trailing))
                            )
                            .clipShape(Capsule())
                        }
                        .disabled(autoFillState == .filling)

                        // Mark Applied
                        Button {
                            withAnimation(.spring(response: 0.3)) { barExpanded = false }
                            markApplied()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: isMarkedApplied ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(isMarkedApplied ? "Applied ✓" : "Mark Applied")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(isMarkedApplied ? Color(hex: "6C63FF") : .white)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(
                                isMarkedApplied
                                    ? AnyShapeStyle(Color(hex: "6C63FF").opacity(0.15))
                                    : AnyShapeStyle(Color(hex: "1C1C1E"))
                            )
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(
                                isMarkedApplied ? Color(hex: "6C63FF") : Color.clear,
                                lineWidth: 1.5))
                        }

                        // Close
                        Button {
                            withAnimation(.spring(response: 0.3)) { barExpanded = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    .transition(.scale(scale: 0.7, anchor: .bottomTrailing).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(.spring(response: 0.35)) { barExpanded = true }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: autoFillState == .done
                                  ? "checkmark.circle.fill" : "wand.and.stars")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(autoFillState == .done ? Color(hex: "10B981") : .white)
                            if isMarkedApplied {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 13)).foregroundColor(Color(hex: "6C63FF"))
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(
                            autoFillState == .done
                                ? AnyShapeStyle(Color(hex: "10B981").opacity(0.15))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: portal.color), Color(hex: "A78BFA")],
                                    startPoint: .leading, endPoint: .trailing))
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: portal.color).opacity(0.4), radius: 10, y: 4)
                    }
                    .transition(.scale(scale: 0.7, anchor: .bottomTrailing).combined(with: .opacity))
                }
            }
            .padding(.trailing, 16).padding(.bottom, 28)
        }
        .animation(.spring(response: 0.35), value: barExpanded)
    }

    // ── Toolbar ────────────────────────────────────────────────────────────────
    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 14) {
                if ctrl.canGoBack {
                    Button { ctrl.webView?.goBack() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .medium))
                    }
                }
                if ctrl.canGoForward {
                    Button { ctrl.webView?.goForward() } label: {
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium))
                    }
                }
                Button { ctrl.webView?.reload() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 14))
                }
            }
        }
    }

    // ── Auto-fill ──────────────────────────────────────────────────────────────
    private func runAutoFill() {
        guard let wv = ctrl.webView else { return }
        withAnimation { autoFillState = .filling }
        let js = buildAutoFillJS(userDataJSON: buildUserDataJSON())
        wv.evaluateJavaScript(js) { result, _ in
            DispatchQueue.main.async {
                if let str = result as? String,
                   let data = str.data(using: .utf8),
                   let arr  = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                    filledFields = arr.compactMap {
                        guard let l = $0["label"], let v = $0["value"] else { return nil }
                        return (label: l, value: v)
                    }
                } else { filledFields = [] }
                withAnimation { autoFillState = .done }
                showReview = true
            }
        }
    }

    // ── Submit ─────────────────────────────────────────────────────────────────
    private func runSubmit() {
        showReview = false
        ctrl.webView?.evaluateJavaScript(submitFormScript) { _, _ in
            DispatchQueue.main.async { markApplied() }
        }
    }

    // ── Mark applied ───────────────────────────────────────────────────────────
    private func markApplied() {
        guard !isMarkedApplied,
              let url = ctrl.currentURL,
              let title = ctrl.webView?.title
        else { return }

        // Build a synthetic Job from the current page
        let syntheticJob = Job(
            id:          url,
            title:       title.isEmpty ? "Job at \(ctrl.currentDomain)" : title,
            company:     ctrl.currentDomain,
            location:    "Via \(portal.name)",
            description: "",
            url:         url,
            salary:      "",
            posted_at:   "",
            category:    portal.name
        )
        aStore.markApplied(syntheticJob)
        withAnimation(.spring(response: 0.4)) { isMarkedApplied = true }
        withAnimation { showAppliedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showAppliedBanner = false }
        }
    }

    // ── Build user data ────────────────────────────────────────────────────────
    private func buildUserDataJSON() -> String {
        let name        = profile?.name         ?? ""
        let email       = profile?.email        ?? ""
        let phone       = profile?.phone        ?? ""
        let linkedin    = jobPref?.linkedin_url  ?? ""
        let experience  = jobPref?.experience    ?? ""
        let currentCTC  = jobPref?.current_ctc   ?? ""
        let expectedCTC = jobPref?.expected_ctc  ?? ""
        let skills      = jobPref?.skills        ?? ""
        let role        = profile?.job_role      ?? ""
        let notice      = jobPref?.notice_period ?? ""
        let cover = "Hi, I am \(name), a \(role) with \(experience) year(s) of experience. " +
                    "My core skills include \(skills). " +
                    "I am open to exciting opportunities and would love to contribute to your team."

        let dict: [String: String] = [
            "name": name,
            "firstName": name.components(separatedBy: " ").first ?? name,
            "lastName": name.components(separatedBy: " ").dropFirst().joined(separator: " "),
            "email": email, "phone": phone, "linkedin": linkedin,
            "experience": experience, "currentCTC": currentCTC,
            "expectedCTC": expectedCTC, "skills": skills,
            "coverLetter": cover, "role": role, "noticePeriod": notice,
        ]
        let data = try? JSONSerialization.data(withJSONObject: dict)
        return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
    }
}

// ── Portal browser controller ─────────────────────────────────────────────────

class PortalBrowserController: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var progress:      Double  = 0
    @Published var canGoBack:     Bool    = false
    @Published var canGoForward:  Bool    = false
    @Published var currentURL:    String? = nil
    @Published var pageTitle:     String  = ""
    @Published var currentDomain: String  = ""

    var webView:        WKWebView?
    var profileEmail:   String = ""
    var userDataJSON:   String = "{}"

    private var progressObs: NSKeyValueObservation?
    private var backObs:     NSKeyValueObservation?
    private var fwdObs:      NSKeyValueObservation?
    private var titleObs:    NSKeyValueObservation?

    func attach(_ wv: WKWebView) {
        webView = wv
        wv.navigationDelegate = self
        progressObs = wv.observe(\.estimatedProgress) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
        }
        backObs = wv.observe(\.canGoBack) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
        }
        fwdObs = wv.observe(\.canGoForward) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.canGoForward = wv.canGoForward }
        }
        titleObs = wv.observe(\.title) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.pageTitle = wv.title ?? "" }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.progress     = 1.0
            self.canGoBack    = webView.canGoBack
            self.canGoForward = webView.canGoForward
            self.currentURL   = webView.url?.absoluteString
            self.currentDomain = webView.url?.host?
                .replacingOccurrences(of: "www.", with: "") ?? ""
        }
        // Auto-login on every page
        if !profileEmail.isEmpty {
            webView.evaluateJavaScript(buildAutoLoginJS(email: profileEmail), completionHandler: nil)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.currentURL = webView.url?.absoluteString
        }
    }
}

// ── Portal browser representable ──────────────────────────────────────────────

struct PortalBrowserRepresentable: UIViewRepresentable {
    let startURL:     String
    let controller:   PortalBrowserController
    let userDataJSON: String
    let profileEmail: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()   // persistent session
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
                             "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
                             "Version/17.0 Mobile/15E148 Safari/604.1"
        controller.attach(wv)
        controller.userDataJSON  = userDataJSON
        controller.profileEmail  = profileEmail
        if let url = URL(string: startURL) { wv.load(URLRequest(url: url)) }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        controller.userDataJSON = userDataJSON
        controller.profileEmail = profileEmail
    }
}

// ── Old portal-specific script — replaced by AutoFillEngine.buildAutoFillJS ──
// Kept as dead code placeholder so the file compiles with no missing references.
private func _unused_portalAutoFillScript(userDataJSON: String, portalID: String) -> String { """
(function() {
    var u = \(userDataJSON);
    var host = window.location.hostname.toLowerCase();

    // ── Shared helpers ──────────────────────────────────────────────────────
    function setVal(el, value) {
        if (!el || !value) return false;
        if (el.tagName === 'SELECT') {
            for (var i = 0; i < el.options.length; i++) {
                if (el.options[i].text.toLowerCase().indexOf(value.toLowerCase()) >= 0) {
                    el.selectedIndex = i;
                    el.dispatchEvent(new Event('change', { bubbles: true }));
                    return true;
                }
            }
            return false;
        }
        try {
            var proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
            var nativeSetter = Object.getOwnPropertyDescriptor(proto, 'value');
            if (nativeSetter && nativeSetter.set) nativeSetter.set.call(el, value);
            else el.value = value;
        } catch(e) { el.value = value; }
        ['input','change','blur','keyup','keydown'].forEach(function(t) {
            el.dispatchEvent(new Event(t, { bubbles: true }));
        });
        // React synthetic events
        var synth = new InputEvent('input', { bubbles: true, cancelable: true, data: value });
        el.dispatchEvent(synth);
        return true;
    }

    function getLabel(el) {
        if (el.id) {
            var lbl = document.querySelector('label[for="' + CSS.escape(el.id) + '"]');
            if (lbl) return lbl.innerText.replace(/[*:\\n]/g,' ').trim();
        }
        var node = el.parentElement;
        for (var i = 0; i < 6 && node; i++, node = node.parentElement) {
            var lbl = node.querySelector('label');
            if (lbl && lbl !== el) return lbl.innerText.replace(/[*:\\n]/g,' ').trim();
            if (node.tagName === 'FORM') break;
        }
        return el.getAttribute('placeholder') || el.getAttribute('aria-label') || el.name || el.id || 'Field';
    }

    function score(el, keys) {
        var h = [el.name || '', el.id || '', el.placeholder || '',
                 el.getAttribute('aria-label') || '',
                 el.getAttribute('data-field') || '',
                 el.getAttribute('autocomplete') || '',
                 el.getAttribute('data-automation') || '',
                 el.className || '']
            .join(' ').toLowerCase().replace(/[-_\\s]/g,'');
        return keys.some(function(k) { return h.indexOf(k.replace(/[-_\\s]/g,'')) >= 0; });
    }

    var filled = [], seen = new Set();

    function fillOne(el, val) {
        if (!el || !val) return;
        var rect = el.getBoundingClientRect();
        if (rect.width === 0 && rect.height === 0) return;
        var uid = (el.name||'') + '|' + (el.id||'') + '|' + (el.placeholder||'');
        if (seen.has(uid)) return;
        if (setVal(el, val)) {
            seen.add(uid);
            filled.push({ label: getLabel(el), value: val });
        }
    }

    // ── LinkedIn Easy Apply ──────────────────────────────────────────────────
    if (host.includes('linkedin.com')) {
        var modal = document.querySelector('.jobs-easy-apply-content, .jobs-easy-apply-modal, [data-test-modal]');
        var ctx = modal || document;

        var pairs = [
            ['#first-name, [name=firstName], [id*=first][id*=name]', u.firstName],
            ['#last-name, [name=lastName], [id*=last][id*=name]',    u.lastName],
            ['#email-address, [name=email], [id*=email]',            u.email],
            ['[name*=phone], [id*=phone], [placeholder*=phone i]',   u.phone],
            ['[name*=headline], [id*=headline]',                     u.role],
            ['[name*=summary], [id*=summary], textarea[id*=summary]', u.coverLetter],
        ];
        pairs.forEach(function(p) {
            try {
                var el = ctx.querySelector(p[0]);
                fillOne(el, p[1]);
            } catch(e) {}
        });
    }

    // ── Naukri ───────────────────────────────────────────────────────────────
    else if (host.includes('naukri.com')) {
        // Chat-bot application form
        var maps = [
            { sel: '[placeholder*="full name" i], [placeholder*="your name" i], [name*=name i]', val: u.name },
            { sel: '[placeholder*="email" i], [name*=email i]', val: u.email },
            { sel: '[placeholder*="mobile" i], [placeholder*="phone" i], [name*=phone i]', val: u.phone },
            { sel: '[placeholder*="current" i][placeholder*="ctc" i], [name*=currentCTC i]', val: u.currentCTC },
            { sel: '[placeholder*="expected" i][placeholder*="ctc" i], [name*=expectedCTC i]', val: u.expectedCTC },
            { sel: '[placeholder*="notice" i], [name*=notice i]', val: u.noticePeriod },
            { sel: '[placeholder*="experience" i], [name*=experience i]', val: u.experience },
            { sel: 'textarea[placeholder*="cover" i], textarea[placeholder*="message" i]', val: u.coverLetter },
        ];
        maps.forEach(function(m) {
            try { fillOne(document.querySelector(m.sel), m.val); } catch(e) {}
        });
    }

    // ── Greenhouse ───────────────────────────────────────────────────────────
    else if (host.includes('greenhouse.io') || host.includes('boards.greenhouse.io')) {
        var ghMap = [
            ['#first_name, [id=first_name]',  u.firstName],
            ['#last_name, [id=last_name]',    u.lastName],
            ['#email, [id=email]',            u.email],
            ['#phone, [id=phone]',            u.phone],
            ['[id*=linkedin_profile], [id*=linkedin]', u.linkedin],
            ['[name*=cover], textarea[id*=cover]', u.coverLetter],
        ];
        ghMap.forEach(function(p) {
            try { fillOne(document.querySelector(p[0]), p[1]); } catch(e) {}
        });
    }

    // ── Lever ────────────────────────────────────────────────────────────────
    else if (host.includes('lever.co')) {
        var leverMap = [
            ['[name=name]',       u.name],
            ['[name=email]',      u.email],
            ['[name=phone]',      u.phone],
            ['[name*=linkedin]',  u.linkedin],
            ['[name*=comments], textarea', u.coverLetter],
        ];
        leverMap.forEach(function(p) {
            try { fillOne(document.querySelector(p[0]), p[1]); } catch(e) {}
        });
    }

    // ── Instahyre ────────────────────────────────────────────────────────────
    else if (host.includes('instahyre.com')) {
        var iMap = [
            ['[placeholder*="name" i]:not([placeholder*="company" i])', u.name],
            ['[placeholder*="email" i], [name*=email i]', u.email],
            ['[placeholder*="phone" i], [placeholder*="mobile" i]', u.phone],
            ['[placeholder*="experience" i], [placeholder*="years" i]', u.experience],
            ['[placeholder*="current" i][placeholder*="salary" i]', u.currentCTC],
            ['[placeholder*="expected" i][placeholder*="salary" i]', u.expectedCTC],
            ['[placeholder*="notice" i]', u.noticePeriod],
            ['textarea', u.coverLetter],
        ];
        iMap.forEach(function(p) {
            try { fillOne(document.querySelector(p[0]), p[1]); } catch(e) {}
        });
    }

    // ── Cutshort ─────────────────────────────────────────────────────────────
    else if (host.includes('cutshort.io')) {
        var csMap = [
            ['[name*=name], [placeholder*="name" i]', u.name],
            ['[name*=email], [placeholder*="email" i]', u.email],
            ['[name*=phone], [placeholder*="phone" i]', u.phone],
            ['[name*=experience], [placeholder*="experience" i]', u.experience],
            ['textarea[name*=note], textarea[placeholder*="note" i]', u.coverLetter],
        ];
        csMap.forEach(function(p) {
            try { fillOne(document.querySelector(p[0]), p[1]); } catch(e) {}
        });
    }

    // ── Wellfound / AngelList ────────────────────────────────────────────────
    else if (host.includes('wellfound.com') || host.includes('angel.co')) {
        var wfMap = [
            ['input[placeholder*="name" i]',       u.name],
            ['input[placeholder*="email" i]',      u.email],
            ['input[placeholder*="phone" i]',      u.phone],
            ['input[placeholder*="linkedin" i]',   u.linkedin],
            ['textarea[placeholder*="cover" i], textarea[placeholder*="note" i]', u.coverLetter],
        ];
        wfMap.forEach(function(p) {
            try { fillOne(document.querySelector(p[0]), p[1]); } catch(e) {}
        });
    }

    // ── Workday ──────────────────────────────────────────────────────────────
    else if (host.includes('myworkday.com') || host.includes('wd1.myworkday') || host.includes('wd3.myworkday')) {
        // Workday uses data-automation attributes
        var wdMap = [
            ['[data-automation-id*=legalName], [data-automation-id*=name]',   u.name],
            ['[data-automation-id*=email]',  u.email],
            ['[data-automation-id*=phone]',  u.phone],
            ['[data-automation-id*=coverLetter] textarea', u.coverLetter],
        ];
        wdMap.forEach(function(p) {
            try { fillOne(document.querySelector(p[0]), p[1]); } catch(e) {}
        });
    }

    // ── Generic fallback (Indeed, Glassdoor, Hirist, iimjobs, Foundit, etc.) ─
    else {
        var genericMaps = [
            { keys: ['firstname','first_name','fname','given'],        val: u.firstName   },
            { keys: ['lastname','last_name','lname','surname'],        val: u.lastName    },
            { keys: ['fullname','full_name','yourname','name','applicant'], val: u.name    },
            { keys: ['email','mail'],                                  val: u.email       },
            { keys: ['phone','mobile','tel','cell','contact'],         val: u.phone       },
            { keys: ['linkedin','linkedinurl','linkedin_profile'],     val: u.linkedin    },
            { keys: ['experience','totalexp','yearsofe','workexp'],    val: u.experience  },
            { keys: ['currentctc','current_ctc','currentsalary','presentsalary'], val: u.currentCTC  },
            { keys: ['expectedctc','expected_ctc','expectedsalary','desiреd'],    val: u.expectedCTC },
            { keys: ['notice','noticeperiod'],                        val: u.noticePeriod},
            { keys: ['skills','keyskills','skill_set'],               val: u.skills      },
            { keys: ['cover','coverletter','message','summary','note','about','motivation'], val: u.coverLetter },
            { keys: ['jobtitle','role','position','currentrole'],     val: u.role        },
        ];
        var inputs = document.querySelectorAll(
            'input:not([type=hidden]):not([type=submit]):not([type=button])' +
            ':not([type=checkbox]):not([type=radio]):not([type=file]):not([type=password]),' +
            'textarea'
        );
        inputs.forEach(function(el) {
            for (var i = 0; i < genericMaps.length; i++) {
                var m = genericMaps[i];
                if (!m.val) continue;
                if (score(el, m.keys)) { fillOne(el, m.val); break; }
            }
        });
    }

    return JSON.stringify(filled);
})();
""" }

// ── Old auto-login — replaced by AutoFillEngine.buildAutoLoginJS ──────────────
private func _unused_browserAutoLoginScript(email: String) -> String { """
(function() {
    var email = \(email);
    if (!email) return;
    function setVal(el, v) {
        if (!el) return;
        try {
            var d = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value');
            if (d && d.set) d.set.call(el, v); else el.value = v;
        } catch(e) { el.value = v; }
        ['input','change','blur'].forEach(function(t) {
            el.dispatchEvent(new Event(t, { bubbles: true }));
        });
    }
    // Fill any visible email/username field
    var sels = ['input[type=email]','input[name*=email i]','input[id*=email i]',
                'input[placeholder*=email i]','input[name*=user i]','input[name*=login i]'];
    for (var s of sels) {
        var el = document.querySelector(s);
        if (el && el.offsetParent !== null) { setVal(el, email); }
    }
    // Click Google SSO if present (no Google session needed from portal itself)
    var googleKw = ['sign in with google','continue with google','google sign in',
                    'login with google','sign up with google'];
    var btns = Array.from(document.querySelectorAll('button,[role=button],a'));
    for (var kw of googleKw) {
        var btn = btns.find(function(b) {
            return (b.innerText||b.getAttribute('aria-label')||'').toLowerCase().includes(kw);
        });
        if (btn) { btn.click(); break; }
    }
})();
""" }

// ── Old submit — replaced by AutoFillEngine.submitFormScript ──────────────────
private let _unused_portalSubmitScript = """
(function() {
    var btn = document.querySelector('button[type=submit], input[type=submit]');
    if (!btn) {
        var all = Array.from(document.querySelectorAll('button,[role=button]'));
        var kws = ['submit application','apply now','apply','send','submit'];
        for (var k of kws) {
            btn = all.find(function(b){return(b.innerText||'').trim().toLowerCase().includes(k);});
            if (btn) break;
        }
    }
    if (btn) { btn.click(); return 'ok'; }
    var f = document.querySelector('form');
    if (f) { f.submit(); return 'form'; }
    return 'not_found';
})();
"""


// ── Auto-fill review sheet for portal browser ─────────────────────────────────

struct PortalAutoFillReview: View {
    let portalName:   String
    let filledFields: [(label: String, value: String)]
    let onSubmit:     () -> Void
    let onDismiss:    () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Summary
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color(hex: "10B981").opacity(0.12)).frame(width: 50, height: 50)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24)).foregroundColor(Color(hex: "10B981"))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(filledFields.isEmpty ? "No fields detected" : "Ready to submit")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Text("\(filledFields.count) fields filled on \(portalName)")
                                    .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(16).background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                        if !filledFields.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(filledFields.enumerated()), id: \.offset) { i, f in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 13)).foregroundColor(Color(hex: "10B981"))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(f.label)
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                            Text(f.value)
                                                .font(.system(size: 13, design: .rounded))
                                                .foregroundColor(.black).lineLimit(2)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 11)
                                    if i < filledFields.count - 1 { Divider().padding(.leading, 40) }
                                }
                            }
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                        }

                        // Submit
                        Button(action: onSubmit) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Application")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(LinearGradient(
                                colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button("Close & review manually") { onDismiss() }
                            .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { onDismiss() }.foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
