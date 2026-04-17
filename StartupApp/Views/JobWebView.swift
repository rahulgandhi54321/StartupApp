import SwiftUI
import WebKit

// ── Job WebView ────────────────────────────────────────────────────────────────
// Persistent WKWebsiteDataStore.default() → portal sessions survive across launches.
// On every page load:  1) auto-login (fill email + click Google SSO if present)
//                      2) auto-fill any job application form fields
// Bottom CTA:          Auto-fill → Review → Submit → Mark as Applied

struct JobWebView: View {
    let job:      Job
    let profile:  SupabaseService.ProfileRow?
    let jobPref:  SupabaseService.JobPrefRow?

    @StateObject private var ctrl         = JobWebController()
    @State private var showReview         = false
    @State private var filledFields: [(label: String, value: String)] = []
    @State private var isSubmitted        = false
    @State private var showSubmitBanner   = false
    @State private var showAppliedBanner  = false
    @State private var autoFillState: AutoFillState = .idle
    @State private var isMarkedApplied    = false
    @State private var barExpanded        = false   // collapsed by default — tap wand to expand

    @ObservedObject private var appliedStore = AppliedJobsStore.shared

    enum AutoFillState { case idle, filling, done }

    // ── Body ───────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack(alignment: .top) {

            // WebView pushes up to make room for the bottom bar
            JobWebViewRepresentable(
                urlString:    job.url,
                controller:   ctrl,
                userDataJSON: makeUserDataJSON(),
                profileEmail: profile?.email ?? ""
            )
            .ignoresSafeArea(edges: .top)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }

            // Top progress bar
            if ctrl.progress < 1.0 {
                VStack {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color(hex: "6C63FF"))
                            .frame(width: geo.size.width * ctrl.progress, height: 3)
                            .animation(.linear(duration: 0.15), value: ctrl.progress)
                    }.frame(height: 3)
                    Spacer()
                }
            }

            // Banners
            bannerLayer
        }
        .navigationTitle(job.company)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showReview) {
            AutoFillReviewSheet(
                job:          job,
                filledFields: filledFields,
                onSubmit:     { runSubmit() },
                onDismiss:    { showReview = false }
            )
        }
        .onAppear {
            isMarkedApplied = appliedStore.isApplied(job)
        }
    }

    // ── Banner layer ───────────────────────────────────────────────────────────
    @ViewBuilder private var bannerLayer: some View {
        if showSubmitBanner || showAppliedBanner {
            VStack {
                if showSubmitBanner {
                    BannerView(icon: "checkmark.circle.fill", color: "10B981",
                               text: "Application submitted! 🎉")
                }
                if showAppliedBanner {
                    BannerView(icon: "bookmark.fill", color: "6C63FF",
                               text: "Marked as Applied ✓")
                }
                Spacer()
            }
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // ── Bottom action bar — sits BELOW the webpage (safeAreaInset) ─────────────
    // Never overlaps the page. Always fully visible and tappable.
    private var bottomBar: some View {
        HStack(spacing: 10) {

            // ── Auto-fill / Review button ──────────────────────────────────────
            Button {
                if autoFillState == .done { showReview = true }
                else { runAutoFill() }
            } label: {
                HStack(spacing: 8) {
                    if autoFillState == .filling {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: autoFillState == .done
                              ? "checkmark.circle.fill" : "wand.and.stars")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(autoFillState == .filling ? "Filling…" :
                         autoFillState == .done    ? "Review & Submit" : "Auto-fill Form")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    autoFillState == .done
                        ? AnyShapeStyle(Color(hex: "10B981"))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                            startPoint: .leading, endPoint: .trailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(.spring(response: 0.3), value: autoFillState)
            }
            .disabled(autoFillState == .filling)

            // ── Mark Applied ───────────────────────────────────────────────────
            Button { markApplied() } label: {
                HStack(spacing: 6) {
                    Image(systemName: isMarkedApplied ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isMarkedApplied ? "Applied" : "Mark")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(isMarkedApplied ? Color(hex: "6C63FF") : Color(hex: "1C1C1E"))
                .padding(.vertical, 13).padding(.horizontal, 14)
                .background(
                    isMarkedApplied
                        ? Color(hex: "6C63FF").opacity(0.1)
                        : Color(hex: "F0F0F0")
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                    isMarkedApplied ? Color(hex: "6C63FF") : Color.clear, lineWidth: 1.5))
                .animation(.spring(response: 0.3), value: isMarkedApplied)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.black.opacity(0.1)),
                 alignment: .top)
    }

    // ── Toolbar ────────────────────────────────────────────────────────────────
    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                if ctrl.canGoBack {
                    Button { ctrl.webView?.goBack() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 15, weight: .medium))
                    }
                }
                Button { ctrl.webView?.reload() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 15))
                }
            }
        }
    }

    // ── Auto-fill ──────────────────────────────────────────────────────────────
    private func runAutoFill() {
        guard let wv = ctrl.webView else { return }
        withAnimation { autoFillState = .filling }
        let js = buildAutoFillJS(userDataJSON: makeUserDataJSON())
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
            DispatchQueue.main.async {
                isSubmitted = true
                withAnimation { showSubmitBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showSubmitBanner = false }
                }
                // Auto-mark as applied on submit
                markApplied()
            }
        }
    }

    // ── Mark as Applied ────────────────────────────────────────────────────────
    private func markApplied() {
        guard !isMarkedApplied else { return }
        appliedStore.markApplied(job)
        withAnimation(.spring(response: 0.4)) { isMarkedApplied = true }
        withAnimation { showAppliedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showAppliedBanner = false }
        }
    }

    // ── Build user data JSON (delegates to AutoFillEngine global function) ───────
    func makeUserDataJSON() -> String {
        buildUserDataJSON(profile: profile, jobPref: jobPref,
                          jobTitle: job.title, company: job.company)
    }
}

// ── Banner view ───────────────────────────────────────────────────────────────

struct BannerView: View {
    let icon: String; let color: String; let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Color(hex: color))
            Text(text).font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 12)
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal, 20).padding(.top, 4)
    }
}

// ── Auto-fill JS (form fields) ────────────────────────────────────────────────

// old script removed — now using AutoFillEngine.buildAutoFillJS
private func _unused_autoFillFormScript(userDataJSON: String) -> String { """
(function() {
    var u = \(userDataJSON);
    var maps = [
        { keys: ['name'], val: u.name },
    ];

    function fill(el, value) {
        if (!value) return false;
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
            var proto = el.tagName === 'TEXTAREA'
                ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
            var desc  = Object.getOwnPropertyDescriptor(proto, 'value');
            if (desc && desc.set) desc.set.call(el, value);
            else el.value = value;
        } catch(e) { el.value = value; }
        ['input','change','blur','keyup'].forEach(function(t) {
            el.dispatchEvent(new Event(t, { bubbles: true }));
        });
        return true;
    }

    function getLabel(el) {
        if (el.id) {
            var lbl = document.querySelector('label[for="' + el.id + '"]');
            if (lbl) return lbl.innerText.replace(/[*:\\n]/g,' ').trim();
        }
        var node = el.parentElement;
        for (var i = 0; i < 5 && node; i++, node = node.parentElement) {
            var lbl = node.querySelector('label');
            if (lbl && lbl !== el) return lbl.innerText.replace(/[*:\\n]/g,' ').trim();
            if (node.tagName === 'FORM') break;
        }
        return el.getAttribute('placeholder') || el.name || el.id || 'Field';
    }

    function score(el, keys) {
        var h = [el.name, el.id, el.placeholder,
                 el.getAttribute('aria-label') || '',
                 el.getAttribute('data-field')  || '',
                 el.getAttribute('autocomplete')|| '',
                 el.className].join(' ').toLowerCase().replace(/[-_\\s]/g,'');
        return keys.some(function(k) {
            return h.indexOf(k.replace(/[-_\\s]/g,'')) >= 0;
        });
    }

    var inputs = document.querySelectorAll(
        'input:not([type=hidden]):not([type=submit]):not([type=button])' +
        ':not([type=checkbox]):not([type=radio]):not([type=file]):not([type=password]),' +
        'textarea'
    );

    var filled = [], seen = new Set();
    inputs.forEach(function(el) {
        var rect = el.getBoundingClientRect();
        if (rect.width === 0 && rect.height === 0) return;
        var uid = (el.name||'') + '|' + (el.id||'') + '|' + (el.placeholder||'');
        if (seen.has(uid)) return;
        for (var i = 0; i < maps.length; i++) {
            var m = maps[i];
            if (!m.val) continue;
            if (score(el, m.keys)) {
                if (fill(el, m.val)) {
                    seen.add(uid);
                    filled.push({ label: getLabel(el), value: m.val });
                }
                break;
            }
        }
    });
    return JSON.stringify(filled);
})();
""" }

// ── WKWebView controller ──────────────────────────────────────────────────────

class JobWebController: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var progress:  Double = 0
    @Published var canGoBack: Bool   = false
    var webView:        WKWebView?
    var userDataJSON:   String = "{}"   // injected from view
    var profileEmail:   String = ""

    private var progressObs: NSKeyValueObservation?
    private var backObs:     NSKeyValueObservation?

    func attach(_ wv: WKWebView) {
        webView = wv
        wv.navigationDelegate = self
        progressObs = wv.observe(\.estimatedProgress) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
        }
        backObs = wv.observe(\.canGoBack) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.progress  = 1.0
            self.canGoBack = webView.canGoBack
        }
        // Run auto-login on every page load
        if !profileEmail.isEmpty {
            webView.evaluateJavaScript(buildAutoLoginJS(email: profileEmail), completionHandler: nil)
        }
    }
}

// ── WKWebView representable (persistent cookies) ──────────────────────────────

struct JobWebViewRepresentable: UIViewRepresentable {
    let urlString:    String
    let controller:   JobWebController
    let userDataJSON: String
    var profileEmail: String = ""

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()   // ← persistent sessions
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
                             "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
                             "Version/17.0 Mobile/15E148 Safari/604.1"
        controller.attach(wv)
        controller.userDataJSON  = userDataJSON
        controller.profileEmail  = profileEmail
        if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        controller.userDataJSON = userDataJSON
        controller.profileEmail = profileEmail
    }
}

// ── Review sheet ──────────────────────────────────────────────────────────────

struct AutoFillReviewSheet: View {
    let job:          Job
    let filledFields: [(label: String, value: String)]
    let onSubmit:     () -> Void
    let onDismiss:    () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                if filledFields.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.questionmark")
                            .font(.system(size: 48)).foregroundColor(.secondary.opacity(0.4))
                        Text("No fillable fields found")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("This portal may require you to log in first, or the form may be behind a custom UI. Fill the fields manually and tap Submit.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                        Button("Got it") { onDismiss() }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white).padding(.horizontal, 40).padding(.vertical, 13)
                            .background(Color(hex: "6C63FF")).clipShape(Capsule())
                    }.padding(32)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Summary
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "10B981").opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(Color(hex: "10B981"))
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Ready to submit")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    Text("\(filledFields.count) fields filled for \(job.company)")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16).background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                            // Fields
                            VStack(alignment: .leading, spacing: 0) {
                                Text("FILLED FIELDS")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary).padding(.horizontal, 4).padding(.bottom, 6)
                                VStack(spacing: 0) {
                                    ForEach(Array(filledFields.enumerated()), id: \.offset) { i, f in
                                        HStack(spacing: 12) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "10B981"))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(f.label)
                                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                Text(f.value)
                                                    .font(.system(size: 14, design: .rounded))
                                                    .foregroundColor(.black).lineLimit(2)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 12)
                                        if i < filledFields.count - 1 {
                                            Divider().padding(.leading, 42)
                                        }
                                    }
                                }
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            }

                            // Info
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Color(hex: "F59E0B"))
                                Text("Review the form in the background before tapping Submit.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color(hex: "F59E0B").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Submit
                            Button(action: onSubmit) {
                                HStack(spacing: 10) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Application")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient(
                                    colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                    startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color(hex: "6C63FF").opacity(0.35), radius: 8, y: 4)
                            }

                            Button("Go back and review manually") { onDismiss() }
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Review Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { onDismiss() }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
