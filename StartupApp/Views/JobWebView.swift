import SwiftUI
import WebKit

// ── Job WebView (persistent session + auto-fill) ──────────────────────────────

struct JobWebView: View {
    let job:      Job
    let profile:  SupabaseService.ProfileRow?
    let jobPref:  SupabaseService.JobPrefRow?

    @StateObject private var ctrl    = JobWebController()
    @State private var showReview    = false
    @State private var filledFields: [(label: String, value: String)] = []
    @State private var isSubmitted   = false
    @State private var showBanner    = false
    @State private var autoFillState: AutoFillState = .idle

    enum AutoFillState { case idle, filling, done }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── WebView ────────────────────────────────────────────────────
            JobWebViewRepresentable(urlString: job.url, controller: ctrl)
                .ignoresSafeArea(edges: .bottom)

            // ── Top progress bar ───────────────────────────────────────────
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

            // ── Submit success banner ──────────────────────────────────────
            if showBanner {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "10B981"))
                        Text("Application submitted! 🎉")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 13)
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4).padding(.top, 12)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Auto-fill button ───────────────────────────────────────────
            if !isSubmitted {
                Button { runAutoFill() } label: {
                    HStack(spacing: 10) {
                        if autoFillState == .filling {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        } else {
                            Image(systemName: autoFillState == .done ? "checkmark.circle.fill" : "wand.and.stars")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        Text(autoFillState == .filling ? "Filling…" :
                             autoFillState == .done    ? "Auto-filled ✓ — Review" :
                                                         "Auto-fill Application")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(
                        autoFillState == .done
                            ? AnyShapeStyle(Color(hex: "10B981"))
                            : AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                startPoint: .leading, endPoint: .trailing))
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "6C63FF").opacity(0.4), radius: 12, y: 6)
                    .animation(.spring(response: 0.3), value: autoFillState)
                }
                .disabled(autoFillState == .filling)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(job.company)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
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
        .sheet(isPresented: $showReview) {
            AutoFillReviewSheet(
                job: job,
                filledFields: filledFields,
                onSubmit: { runSubmit() },
                onDismiss: { showReview = false }
            )
        }
    }

    // ── Auto-fill ──────────────────────────────────────────────────────────────
    private func runAutoFill() {
        guard let wv = ctrl.webView else { return }
        withAnimation { autoFillState = .filling }

        let js = autoFillScript(userDataJSON: buildUserDataJSON())
        wv.evaluateJavaScript(js) { result, _ in
            DispatchQueue.main.async {
                if let str = result as? String,
                   let data = str.data(using: .utf8),
                   let arr  = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                    filledFields = arr.compactMap {
                        guard let l = $0["label"], let v = $0["value"] else { return nil }
                        return (label: l, value: v)
                    }
                } else {
                    filledFields = []
                }
                withAnimation { autoFillState = .done }
                showReview = true
            }
        }
    }

    // ── Submit ─────────────────────────────────────────────────────────────────
    private func runSubmit() {
        showReview = false
        ctrl.webView?.evaluateJavaScript(submitScript) { _, _ in
            DispatchQueue.main.async {
                isSubmitted = true
                withAnimation { showBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showBanner = false }
                }
            }
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
        let cover = "Hi, I am \(name), a \(role) with \(experience) year(s) of experience. " +
                    "I am excited to apply for the \(job.title) position at \(job.company). " +
                    "My core skills include \(skills). I look forward to contributing to your team."

        let dict: [String: String] = [
            "name": name, "firstName": name.components(separatedBy: " ").first ?? name,
            "lastName": name.components(separatedBy: " ").dropFirst().joined(separator: " "),
            "email": email, "phone": phone, "linkedin": linkedin,
            "experience": experience, "currentCTC": currentCTC,
            "expectedCTC": expectedCTC, "skills": skills, "coverLetter": cover,
        ]
        let data = try? JSONSerialization.data(withJSONObject: dict)
        return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
    }
}

// ── Auto-fill JS ──────────────────────────────────────────────────────────────

private func autoFillScript(userDataJSON: String) -> String { """
(function() {
    var u = \(userDataJSON);

    // Field mapping: keys to match against name/id/placeholder/aria-label
    var maps = [
        { keys: ['firstname','first_name','given_name','fname'],     val: u.firstName  },
        { keys: ['lastname','last_name','surname','lname','family'],  val: u.lastName   },
        { keys: ['fullname','full_name','name','applicant','your name','candidate'], val: u.name },
        { keys: ['email','mail','e-mail'],                            val: u.email      },
        { keys: ['phone','mobile','tel','contact','phone_number','phoneno','cell'], val: u.phone },
        { keys: ['linkedin','linkedin_url','linkedin_profile','linkedin url'], val: u.linkedin },
        { keys: ['experience','total_exp','years','yrs','exp_years','work_experience'], val: u.experience },
        { keys: ['currentctc','current_ctc','current_salary','cur_ctc','presentctc','present ctc'], val: u.currentCTC },
        { keys: ['expectedctc','expected_ctc','expected_salary','exp_ctc','desired_salary'], val: u.expectedCTC },
        { keys: ['skills','key_skills','keyskills','skill_set','technologies'],     val: u.skills },
        { keys: ['cover','coverletter','cover_letter','message','summary','note','why','motivation','about'], val: u.coverLetter },
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
            var proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
            var desc  = Object.getOwnPropertyDescriptor(proto, 'value');
            if (desc && desc.set) desc.set.call(el, value);
            else el.value = value;
        } catch(e) { el.value = value; }
        ['input','change','blur','keyup'].forEach(function(evt) {
            el.dispatchEvent(new Event(evt, { bubbles: true }));
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
        var haystack = [
            el.name, el.id, el.placeholder,
            el.getAttribute('aria-label') || '',
            el.getAttribute('data-field') || '',
            el.getAttribute('autocomplete') || '',
            el.className,
        ].join(' ').toLowerCase().replace(/[-_\\s]/g, '');

        return keys.some(function(k) {
            return haystack.indexOf(k.replace(/[-_\\s]/g,'')) >= 0;
        });
    }

    var inputs  = document.querySelectorAll(
        'input:not([type=hidden]):not([type=submit]):not([type=button])' +
        ':not([type=checkbox]):not([type=radio]):not([type=file]):not([type=password]),' +
        'textarea'
    );

    var filled = [];
    var seen   = new Set();

    inputs.forEach(function(el) {
        // Skip invisible
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

private let submitScript = """
(function() {
    // Try submit button by type
    var btn = document.querySelector('button[type=submit], input[type=submit]');
    if (!btn) {
        // Keyword match on button text
        var buttons = Array.from(document.querySelectorAll('button, [role=button]'));
        var keywords = ['submit application','apply now','apply','send application','submit'];
        for (var k of keywords) {
            btn = buttons.find(function(b) { return b.innerText.trim().toLowerCase().indexOf(k) >= 0; });
            if (btn) break;
        }
    }
    if (btn) { btn.click(); return 'submitted'; }
    var form = document.querySelector('form');
    if (form) { form.submit(); return 'form_submitted'; }
    return 'not_found';
})();
"""

// ── WKWebView controller + representable (persistent cookies) ─────────────────

class JobWebController: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var progress:  Double = 0
    @Published var canGoBack: Bool   = false
    var webView: WKWebView?
    private var obs: NSKeyValueObservation?
    private var backObs: NSKeyValueObservation?

    func attach(_ wv: WKWebView) {
        webView = wv
        wv.navigationDelegate = self
        obs     = wv.observe(\.estimatedProgress) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
        }
        backObs = wv.observe(\.canGoBack) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { self.progress = 1.0; self.canGoBack = webView.canGoBack }
    }
}

struct JobWebViewRepresentable: UIViewRepresentable {
    let urlString:  String
    let controller: JobWebController

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()  // ← persistent session
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        // Desktop user agent so job portals render correctly
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        controller.attach(wv)
        if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// ── Review Sheet ──────────────────────────────────────────────────────────────

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
                            .font(.system(size: 14, design: .rounded)).foregroundColor(.secondary)
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
                                    Circle().fill(Color(hex: "10B981").opacity(0.15)).frame(width: 50, height: 50)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26)).foregroundColor(Color(hex: "10B981"))
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Ready to submit")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    Text("\(filledFields.count) fields filled for \(job.company)")
                                        .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                            // Fields list
                            VStack(alignment: .leading, spacing: 0) {
                                Text("FILLED FIELDS")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary).padding(.horizontal, 4).padding(.bottom, 6)
                                VStack(spacing: 0) {
                                    ForEach(Array(filledFields.enumerated()), id: \.offset) { i, f in
                                        HStack(spacing: 12) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14)).foregroundColor(Color(hex: "10B981"))
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
                                        if i < filledFields.count - 1 { Divider().padding(.leading, 42) }
                                    }
                                }
                                .background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            }

                            // Warning
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill").foregroundColor(Color(hex: "F59E0B"))
                                Text("Review the form in the background before tapping Submit.")
                                    .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                            }
                            .padding(14).background(Color(hex: "F59E0B").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Submit
                            Button(action: onSubmit) {
                                HStack(spacing: 10) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Application")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
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
                        .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
