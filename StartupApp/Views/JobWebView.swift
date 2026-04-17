import SwiftUI
import WebKit

// ── Main Job WebView screen ───────────────────────────────────────────────────

struct JobWebView: View {
    let job:      Job
    let profile:  SupabaseService.ProfileRow?
    let jobPref:  SupabaseService.JobPrefRow?

    @StateObject private var controller = WebViewController()
    @State private var showReview       = false
    @State private var filledFields: [(label: String, value: String)] = []
    @State private var isSubmitted      = false
    @State private var showSubmitBanner = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── WebView ────────────────────────────────────────────────────
            WebViewRepresentable(urlString: job.url, controller: controller)
                .ignoresSafeArea(edges: .bottom)

            // ── Progress bar ───────────────────────────────────────────────
            if controller.loadProgress < 1.0 {
                VStack {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color(hex: "6C63FF"))
                            .frame(width: geo.size.width * controller.loadProgress, height: 3)
                            .animation(.linear(duration: 0.2), value: controller.loadProgress)
                    }
                    .frame(height: 3)
                    Spacer()
                }
            }

            // ── Submit success banner ──────────────────────────────────────
            if showSubmitBanner {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "10B981"))
                        Text("Application submitted!").font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    Spacer()
                }
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Auto-fill floating button ──────────────────────────────────
            if !isSubmitted {
                Button { runAutoFill() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Auto-fill Application")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "6C63FF").opacity(0.45), radius: 12, y: 6)
                }
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(job.company)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { controller.webView?.reload() } label: {
                    Image(systemName: "arrow.clockwise").font(.system(size: 15))
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

    // ── Run auto-fill JS ───────────────────────────────────────────────────────
    private func runAutoFill() {
        guard let wv = controller.webView else { return }

        let userData = buildUserDataJSON()
        let js = autoFillScript(userDataJSON: userData)

        wv.evaluateJavaScript(js) { result, error in
            DispatchQueue.main.async {
                if let jsonStr = result as? String,
                   let data = jsonStr.data(using: .utf8),
                   let arr  = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                    filledFields = arr.compactMap { d in
                        guard let l = d["label"], let v = d["value"] else { return nil }
                        return (label: l, value: v)
                    }
                    if !filledFields.isEmpty { showReview = true }
                } else {
                    // Nothing filled — still show review so user knows
                    filledFields = []
                    showReview = true
                }
            }
        }
    }

    // ── Submit the form via JS ─────────────────────────────────────────────────
    private func runSubmit() {
        showReview = false
        guard let wv = controller.webView else { return }
        wv.evaluateJavaScript(submitScript) { _, _ in
            DispatchQueue.main.async {
                isSubmitted = true
                withAnimation { showSubmitBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showSubmitBanner = false }
                }
            }
        }
    }

    // ── Build user data JSON for injection ─────────────────────────────────────
    private func buildUserDataJSON() -> String {
        let name       = profile?.name        ?? ""
        let email      = profile?.email       ?? ""
        let phone      = profile?.phone       ?? ""
        let linkedin   = jobPref?.linkedin_url ?? ""
        let experience = jobPref?.experience   ?? ""
        let currentCTC = jobPref?.current_ctc  ?? ""
        let expectedCTC = jobPref?.expected_ctc ?? ""
        let skills     = jobPref?.skills       ?? ""
        let cover = "I am \(name), a \(profile?.job_role ?? "professional") with \(experience) years of experience. I'm excited to apply for the \(job.title) role at \(job.company). My skills include \(skills)."

        let dict: [String: String] = [
            "name": name, "email": email, "phone": phone,
            "linkedin": linkedin, "experience": experience,
            "currentCTC": currentCTC, "expectedCTC": expectedCTC,
            "skills": skills, "coverLetter": cover,
            "firstName": name.components(separatedBy: " ").first ?? name,
            "lastName":  name.components(separatedBy: " ").dropFirst().joined(separator: " "),
        ]
        let data = try? JSONSerialization.data(withJSONObject: dict)
        return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
    }
}

// ── Auto-fill JavaScript ───────────────────────────────────────────────────────

private func autoFillScript(userDataJSON: String) -> String {
    return """
    (function() {
        var u = \(userDataJSON);

        var maps = [
            { keys: ['firstname','first_name','given_name'],           val: u.firstName },
            { keys: ['lastname','last_name','surname','family_name'],   val: u.lastName  },
            { keys: ['fullname','full_name','name','applicant_name','your_name'], val: u.name },
            { keys: ['email','mail','e_mail'],                         val: u.email     },
            { keys: ['phone','mobile','tel','contact','phoneno','phone_number'], val: u.phone },
            { keys: ['linkedin','linkedinurl','linkedin_url','linkedin_profile'], val: u.linkedin },
            { keys: ['experience','years_exp','exp','yrsofexp','total_exp'],     val: u.experience },
            { keys: ['currentctc','current_ctc','currentpackage','cur_ctc','present_ctc'], val: u.currentCTC },
            { keys: ['expectedctc','expected_ctc','expectedpackage','exp_ctc','desired_salary'], val: u.expectedCTC },
            { keys: ['skills','keyskills','skill_set','tech_skills'],  val: u.skills },
            { keys: ['cover','coverletter','message','summary','additional','about','motivation'], val: u.coverLetter },
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
                var proto = el.tagName === 'TEXTAREA' ?
                    window.HTMLTextAreaElement.prototype :
                    window.HTMLInputElement.prototype;
                var setter = Object.getOwnPropertyDescriptor(proto, 'value') &&
                             Object.getOwnPropertyDescriptor(proto, 'value').set;
                if (setter) {
                    setter.call(el, value);
                } else {
                    el.value = value;
                }
            } catch(e) { el.value = value; }
            el.dispatchEvent(new Event('input',  { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
            el.dispatchEvent(new Event('blur',   { bubbles: true }));
            return true;
        }

        function getLabel(el) {
            if (el.id) {
                var lbl = document.querySelector('label[for="' + el.id + '"]');
                if (lbl) return lbl.innerText.replace(/[*:]/g,'').trim();
            }
            var p = el.parentElement;
            for (var i = 0; i < 4 && p; i++, p = p.parentElement) {
                var lbl = p.querySelector('label');
                if (lbl && lbl !== el) return lbl.innerText.replace(/[*:]/g,'').trim();
            }
            return el.placeholder || el.name || el.id || 'Field';
        }

        var fields = document.querySelectorAll(
            'input:not([type=hidden]):not([type=submit]):not([type=button])' +
            ':not([type=checkbox]):not([type=radio]):not([type=file]),' +
            'textarea'
        );

        var filled = [];
        var seen   = new Set();

        fields.forEach(function(el) {
            if (!el.offsetParent && el.style.display === 'none') return;
            var id = (el.name + '|' + el.id + '|' + el.placeholder).toLowerCase();
            if (seen.has(id)) return;

            for (var i = 0; i < maps.length; i++) {
                var m = maps[i];
                if (!m.val) continue;
                var matched = m.keys.some(function(k) {
                    return id.indexOf(k) >= 0 ||
                           (el.getAttribute('aria-label') || '').toLowerCase().indexOf(k) >= 0 ||
                           (el.getAttribute('data-field') || '').toLowerCase().indexOf(k) >= 0;
                });
                if (matched) {
                    if (fill(el, m.val)) {
                        seen.add(id);
                        filled.push({ label: getLabel(el), value: m.val });
                    }
                    break;
                }
            }
        });

        return JSON.stringify(filled);
    })();
    """
}

private let submitScript = """
(function() {
    var btn = document.querySelector(
        'button[type=submit], input[type=submit], ' +
        'button[class*=submit], button[class*=apply], ' +
        'button[id*=submit], button[id*=apply]'
    );
    if (!btn) {
        var all = document.querySelectorAll('button');
        for (var i = 0; i < all.length; i++) {
            var t = all[i].innerText.toLowerCase();
            if (t.indexOf('apply') >= 0 || t.indexOf('submit') >= 0) { btn = all[i]; break; }
        }
    }
    if (btn) { btn.click(); return 'submitted'; }
    var form = document.querySelector('form');
    if (form) { form.submit(); return 'form_submitted'; }
    return 'not_found';
})();
"""

// ── WKWebView representable ───────────────────────────────────────────────────

class WebViewController: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var loadProgress: Double = 0
    var webView: WKWebView?
    private var obs: NSKeyValueObservation?

    func attach(_ wv: WKWebView) {
        webView = wv
        wv.navigationDelegate = self
        obs = wv.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.loadProgress = wv.estimatedProgress }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { self.loadProgress = 1.0 }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let urlString:  String
    let controller: WebViewController

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.allowsBackForwardNavigationGestures = true
        controller.attach(wv)
        if let url = URL(string: urlString) {
            wv.load(URLRequest(url: url))
        }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// ── Auto-fill review sheet ────────────────────────────────────────────────────

struct AutoFillReviewSheet: View {
    let job:          Job
    let filledFields: [(label: String, value: String)]
    let onSubmit:     () -> Void
    let onDismiss:    () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F5FF").ignoresSafeArea()
                VStack(spacing: 0) {
                    if filledFields.isEmpty {
                        // Nothing could be filled
                        VStack(spacing: 16) {
                            Image(systemName: "doc.questionmark")
                                .font(.system(size: 48)).foregroundColor(.secondary.opacity(0.5))
                            Text("No fillable fields found")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            Text("This job site may use a custom form that requires manual input. Tap the fields and fill them yourself.")
                                .font(.system(size: 14, design: .rounded)).foregroundColor(.secondary)
                                .multilineTextAlignment(.center).padding(.horizontal, 32)
                            Button("Got it") { onDismiss() }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white).padding(.horizontal, 40).padding(.vertical, 13)
                                .background(Color(hex: "6C63FF")).clipShape(Capsule())
                        }
                        .padding(32)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Summary card
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color(hex: "10B981").opacity(0.15)).frame(width: 48, height: 48)
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24)).foregroundColor(Color(hex: "10B981"))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Ready to submit")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                        Text("\(filledFields.count) fields auto-filled for \(job.company)")
                                            .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                                // Filled fields list
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("WHAT WAS FILLED")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary).padding(.horizontal, 4).padding(.bottom, 6)

                                    VStack(spacing: 0) {
                                        ForEach(Array(filledFields.enumerated()), id: \.offset) { i, field in
                                            HStack(spacing: 12) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14)).foregroundColor(Color(hex: "10B981"))
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(field.label)
                                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                    Text(field.value)
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

                                // Review note
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle").foregroundColor(Color(hex: "F59E0B"))
                                    Text("Review the filled fields in the form before submitting.")
                                        .font(.system(size: 13, design: .rounded)).foregroundColor(.secondary)
                                }
                                .padding(14)
                                .background(Color(hex: "F59E0B").opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                // Submit button
                                Button(action: onSubmit) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "paperplane.fill")
                                        Text("Submit Application")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                                    .background(
                                        LinearGradient(colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: Color(hex: "6C63FF").opacity(0.35), radius: 8, y: 4)
                                }

                                // Cancel
                                Button("Go back and review manually") { onDismiss() }
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                        }
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
