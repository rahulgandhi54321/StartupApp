import Foundation

// ── Auto-Fill Engine ──────────────────────────────────────────────────────────
// Bulletproof JS auto-fill that:
//  • Always returns valid JSON (outer try/catch)
//  • Searches document + all accessible iframes
//  • Uses React/Angular native-setter trick
//  • Portal-specific selectors for LinkedIn, Naukri, Greenhouse, Lever, etc.
//  • Generic keyword-scoring fallback for any other site

// MARK: - User data builder (shared helper)

func buildUserData(profile: SupabaseService.ProfileRow?,
                   jobPref: SupabaseService.JobPrefRow?,
                   jobTitle: String = "", company: String = "") -> [String: String] {
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
    let resumeURL   = jobPref?.resume_url    ?? ""
    let gender      = profile?.gender        ?? ""
    let locationRaw = jobPref?.location      ?? ""

    // First physical city from pipe-separated prefs (skip remote/hybrid)
    let locationCity: String = {
        let parts = locationRaw.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.first(where: {
            let lo = $0.lowercased()
            return !lo.contains("remote") && !lo.contains("hybrid") && !lo.contains("anywhere")
        }) ?? parts.first ?? ""
    }()

    // Whether user is open to remote
    let remoteOK = locationRaw.lowercased().contains("remote") ? "Yes" : "No"

    let coverFor = jobTitle.isEmpty ? "exciting opportunities" : "the \(jobTitle) position\(company.isEmpty ? "" : " at \(company)")"
    let cover = "Hi, I am \(name), a \(role) with \(experience) year(s) of experience. " +
                "I am excited to apply for \(coverFor). " +
                "My core skills include \(skills). I look forward to contributing to your team."

    return [
        "name":         name,
        "firstName":    name.components(separatedBy: " ").first ?? name,
        "lastName":     name.components(separatedBy: " ").dropFirst().joined(separator: " "),
        "email":        email,
        "phone":        phone,
        "linkedin":     linkedin,
        "experience":   experience,
        "currentCTC":   currentCTC,
        "expectedCTC":  expectedCTC,
        "skills":       skills,
        "coverLetter":  cover,
        "role":         role,
        "noticePeriod": notice,
        "resumeURL":    resumeURL,
        "gender":       gender,
        "location":     locationCity,
        "locationFull": locationRaw,
        "remoteOK":     remoteOK,
        "jobTitle":     jobTitle,
        "company":      company,
    ]
}

func buildUserDataJSON(profile: SupabaseService.ProfileRow?,
                       jobPref: SupabaseService.JobPrefRow?,
                       jobTitle: String = "", company: String = "") -> String {
    let dict = buildUserData(profile: profile, jobPref: jobPref,
                             jobTitle: jobTitle, company: company)
    let data = try? JSONSerialization.data(withJSONObject: dict)
    return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
}

// MARK: - Main entry

func buildAutoFillJS(userDataJSON: String) -> String {
    """
    (function() {
    try {

    var u = \(userDataJSON);

    // ── setValue: works for plain HTML, React, Angular, Vue ──────────────────
    function setVal(el, value) {
        if (!el || value === null || value === undefined || value === '') return false;
        if (el.readOnly || el.disabled) return false;

        if (el.tagName === 'SELECT') {
            var lo = value.toString().toLowerCase();
            for (var i = 0; i < el.options.length; i++) {
                var opt = el.options[i];
                if (opt.text.toLowerCase().includes(lo) ||
                    opt.value.toLowerCase().includes(lo)) {
                    el.selectedIndex = i;
                    fire(el, ['change']);
                    return true;
                }
            }
            return false;
        }

        var val = value.toString();
        // React native setter (handles controlled components)
        try {
            var proto = (el.tagName === 'TEXTAREA')
                ? HTMLTextAreaElement.prototype
                : HTMLInputElement.prototype;
            var setter = Object.getOwnPropertyDescriptor(proto, 'value');
            if (setter && setter.set) {
                setter.set.call(el, val);
            } else {
                el.value = val;
            }
        } catch(e) { el.value = val; }

        fire(el, ['input', 'change', 'blur', 'keyup', 'keydown']);
        return true;
    }

    function fire(el, evts) {
        evts.forEach(function(t) {
            try { el.dispatchEvent(new Event(t, { bubbles: true, cancelable: true })); } catch(e) {}
        });
        // InputEvent for React
        try { el.dispatchEvent(new InputEvent('input', { bubbles: true, cancelable: true, data: el.value })); } catch(e) {}
    }

    // ── Safe querySelector (no CSS.escape needed) ─────────────────────────────
    function qs(ctx, sel) {
        try { return ctx.querySelector(sel); } catch(e) { return null; }
    }
    function qsa(ctx, sel) {
        try { return Array.from(ctx.querySelectorAll(sel)); } catch(e) { return []; }
    }

    // ── Get all searchable contexts (document + iframes) ──────────────────────
    function getContexts() {
        var ctxs = [document];
        try {
            var frames = Array.from(document.querySelectorAll('iframe'));
            frames.forEach(function(f) {
                try { if (f.contentDocument) ctxs.push(f.contentDocument); } catch(e) {}
            });
        } catch(e) {}
        return ctxs;
    }

    // ── Get a human-readable label for a field ────────────────────────────────
    function getLabel(el) {
        // aria-label
        var a = el.getAttribute('aria-label');
        if (a && a.trim()) return a.trim();
        // <label for="...">
        if (el.id) {
            try {
                var lbl = document.querySelector('label[for="' + el.id.replace(/"/g, '\\\\"') + '"]');
                if (lbl) return lbl.innerText.replace(/[*:\\n]/g,' ').trim();
            } catch(e) {}
        }
        // Nearest ancestor label
        var node = el.parentElement;
        for (var i = 0; i < 6 && node; i++, node = node.parentElement) {
            try {
                var lbl2 = node.querySelector('label');
                if (lbl2 && lbl2 !== el) return lbl2.innerText.replace(/[*:\\n]/g,' ').trim();
            } catch(e) {}
            if (node.tagName === 'FORM') break;
        }
        return el.placeholder || el.name || el.id || 'Field';
    }

    // ── Visibility check ──────────────────────────────────────────────────────
    function isVisible(el) {
        try {
            if (!el.offsetParent && el.tagName !== 'TEXTAREA') {
                var s = window.getComputedStyle(el);
                if (s.position !== 'fixed' && s.position !== 'absolute') return false;
            }
            return true;
        } catch(e) { return true; }
    }

    // ── Haystack scoring ──────────────────────────────────────────────────────
    function score(el, keys) {
        var h = [
            el.name || '', el.id || '', el.placeholder || '',
            el.getAttribute('aria-label') || '',
            el.getAttribute('data-field') || '',
            el.getAttribute('data-qa') || '',
            el.getAttribute('data-testid') || '',
            el.getAttribute('autocomplete') || '',
            el.getAttribute('data-automation') || '',
            el.getAttribute('ng-model') || '',
            el.className || ''
        ].join(' ').toLowerCase().replace(/[-_\\s\\.]/g, '');

        return keys.some(function(k) {
            return h.indexOf(k.replace(/[-_\\s\\.]/g, '')) >= 0;
        });
    }

    var filled = [];
    var seen   = new Set();

    function tryFill(el, val) {
        if (!el || !val) return;
        if (!isVisible(el)) return;
        var uid = (el.tagName || '') + '|' + (el.name || '') + '|' +
                  (el.id || '') + '|' + (el.placeholder || '') + '|' + (el.className || '').substring(0, 30);
        if (seen.has(uid)) return;
        if (setVal(el, val)) {
            seen.add(uid);
            filled.push({ label: getLabel(el), value: val.toString() });
        }
    }

    function selectorFill(ctx, pairs) {
        pairs.forEach(function(p) {
            var sels = Array.isArray(p[0]) ? p[0] : [p[0]];
            for (var s of sels) {
                var el = qs(ctx, s);
                if (el) { tryFill(el, p[1]); break; }
            }
        });
    }

    var ctxs = getContexts();
    var host  = window.location.hostname.toLowerCase();

    // ════════════════════════════════════════════════════════════════════════════
    // PORTAL-SPECIFIC FILLS
    // ════════════════════════════════════════════════════════════════════════════

    // ── LinkedIn Easy Apply ───────────────────────────────────────────────────
    if (host.includes('linkedin.com')) {
        ctxs.forEach(function(ctx) {
            var modal = qs(ctx, '.jobs-easy-apply-content') ||
                        qs(ctx, '[data-test-modal]') ||
                        qs(ctx, '.artdeco-modal__content') || ctx;

            selectorFill(modal, [
                [['input[id*="first" i][id*="name" i]', 'input[name*="firstName" i]',
                  'input[autocomplete="given-name"]', '#first-name'], u.firstName],
                [['input[id*="last" i][id*="name" i]',  'input[name*="lastName" i]',
                  'input[autocomplete="family-name"]', '#last-name'], u.lastName],
                [['input[id*="email" i]', 'input[name*="email" i]',
                  'input[autocomplete="email"]', '#email-address'], u.email],
                [['input[id*="phone" i]', 'input[name*="phone" i]',
                  'input[autocomplete*="tel"]'], u.phone],
                [['input[id*="city" i]', 'input[id*="location" i]',
                  'input[name*="city" i]', 'input[placeholder*="city" i]'], u.location],
                [['input[id*="linkedin" i]', 'input[name*="linkedin" i]'], u.linkedin],
                [['input[id*="experience" i]', 'input[name*="experience" i]',
                  'input[placeholder*="experience" i]'], u.experience],
                [['textarea', 'div[contenteditable="true"]'], u.coverLetter],
            ]);

            // Generic pass for dynamic questions (years of exp, CTC, etc.)
            genericFill(modal);
        });
    }

    // ── Naukri ────────────────────────────────────────────────────────────────
    else if (host.includes('naukri.com')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['input[placeholder*="name" i]:not([placeholder*="company" i]):not([placeholder*="org" i])'], u.name],
                [['input[placeholder*="email" i]', 'input[name*="email" i]'], u.email],
                [['input[placeholder*="mobile" i]', 'input[placeholder*="phone" i]',
                  'input[name*="phone" i]', 'input[name*="mobile" i]'], u.phone],
                [['input[placeholder*="current" i][placeholder*="ctc" i]',
                  'input[placeholder*="current" i][placeholder*="salary" i]',
                  'input[id*="currentCTC" i]'], u.currentCTC],
                [['input[placeholder*="expected" i][placeholder*="ctc" i]',
                  'input[placeholder*="expected" i][placeholder*="salary" i]',
                  'input[id*="expectedCTC" i]'], u.expectedCTC],
                [['input[placeholder*="notice" i]', 'select[name*="notice" i]'], u.noticePeriod],
                [['input[placeholder*="experience" i]', 'input[placeholder*="years" i]',
                  'input[id*="experience" i]'], u.experience],
                [['input[placeholder*="location" i]', 'input[placeholder*="city" i]',
                  'input[placeholder*="preferred location" i]'], u.location],
                [['select[name*="gender" i]', 'input[name*="gender" i]'], u.gender],
                [['textarea[placeholder*="cover" i]', 'textarea[placeholder*="message" i]',
                  'textarea:not([style*="display:none"])'], u.coverLetter],
            ]);
            genericFill(ctx);
        });
    }

    // ── Greenhouse ────────────────────────────────────────────────────────────
    else if (host.includes('greenhouse.io')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['#first_name', '[id="first_name"]', 'input[name="first_name"]'], u.firstName],
                [['#last_name',  '[id="last_name"]',  'input[name="last_name"]'],  u.lastName],
                [['#email',      '[id="email"]',       'input[name="email"]'],      u.email],
                [['#phone',      '[id="phone"]',       'input[name="phone"]'],      u.phone],
                [['[id*="linkedin"]', '[name*="linkedin"]'],                         u.linkedin],
                [['[id*="website"]',  '[name*="website"]'],                          u.linkedin],
                [['textarea[id*="cover"]', 'textarea[name*="cover"]',
                  'textarea[id*="message"]', 'textarea'],                            u.coverLetter],
            ]);
        });
    }

    // ── Lever ────────────────────────────────────────────────────────────────
    else if (host.includes('lever.co')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['input[name="name"]', 'input[placeholder*="name" i]'], u.name],
                [['input[name="email"]', 'input[placeholder*="email" i]'], u.email],
                [['input[name="phone"]', 'input[placeholder*="phone" i]'], u.phone],
                [['input[name*="linkedin"]', 'input[placeholder*="linkedin" i]'], u.linkedin],
                [['input[name*="website"]'], u.linkedin],
                [['textarea[name*="comments"]', 'textarea[name*="additional"]',
                  'textarea[placeholder*="cover" i]', 'textarea'], u.coverLetter],
            ]);
        });
    }

    // ── Instahyre ────────────────────────────────────────────────────────────
    else if (host.includes('instahyre.com')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['input[placeholder*="full name" i]', 'input[placeholder*="your name" i]',
                  'input[placeholder*="name" i]:not([placeholder*="company" i])'], u.name],
                [['input[placeholder*="email" i]'], u.email],
                [['input[placeholder*="phone" i]', 'input[placeholder*="mobile" i]'], u.phone],
                [['input[placeholder*="experience" i]', 'input[placeholder*="years" i]'], u.experience],
                [['input[placeholder*="current" i]'], u.currentCTC],
                [['input[placeholder*="expected" i]'], u.expectedCTC],
                [['input[placeholder*="notice" i]'], u.noticePeriod],
                [['textarea'], u.coverLetter],
            ]);
            genericFill(ctx);
        });
    }

    // ── Cutshort ─────────────────────────────────────────────────────────────
    else if (host.includes('cutshort.io')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['input[name*="name"]',  'input[placeholder*="name" i]'], u.name],
                [['input[name*="email"]', 'input[placeholder*="email" i]'], u.email],
                [['input[name*="phone"]', 'input[placeholder*="phone" i]'], u.phone],
                [['input[name*="exp"]',   'input[placeholder*="experience" i]'], u.experience],
                [['textarea'], u.coverLetter],
            ]);
            genericFill(ctx);
        });
    }

    // ── Wellfound / AngelList ────────────────────────────────────────────────
    else if (host.includes('wellfound.com') || host.includes('angel.co')) {
        ctxs.forEach(function(ctx) {
            genericFill(ctx);
        });
    }

    // ── Workday ──────────────────────────────────────────────────────────────
    else if (host.includes('myworkday.com') || host.includes('.wd1.') || host.includes('.wd3.')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['[data-automation-id*="legalName"]', '[data-automation-id*="firstName"]'], u.firstName],
                [['[data-automation-id*="lastName"]'], u.lastName],
                [['[data-automation-id*="email"]'],    u.email],
                [['[data-automation-id*="phone"]'],    u.phone],
            ]);
            genericFill(ctx);
        });
    }

    // ── Indeed ───────────────────────────────────────────────────────────────
    else if (host.includes('indeed.com')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['input[id*="applicant.name" i]', 'input[name*="fullName" i]',
                  'input[aria-label*="name" i]:not([aria-label*="company" i])'], u.name],
                [['input[id*="applicant.phoneNumber" i]', 'input[name*="phone" i]'], u.phone],
                [['input[id*="applicant.email" i]', 'input[name*="email" i]'], u.email],
                [['textarea[name*="cover" i]', 'textarea[aria-label*="cover" i]'], u.coverLetter],
            ]);
            genericFill(ctx);
        });
    }

    // ── Glassdoor ────────────────────────────────────────────────────────────
    else if (host.includes('glassdoor.')) {
        ctxs.forEach(function(ctx) {
            genericFill(ctx);
        });
    }

    // ── Hirist ───────────────────────────────────────────────────────────────
    else if (host.includes('hirist.')) {
        ctxs.forEach(function(ctx) { genericFill(ctx); });
    }

    // ── iimjobs ───────────────────────────────────────────────────────────────
    else if (host.includes('iimjobs.com')) {
        ctxs.forEach(function(ctx) { genericFill(ctx); });
    }

    // ── Foundit / Monster ─────────────────────────────────────────────────────
    else if (host.includes('foundit.') || host.includes('monster.')) {
        ctxs.forEach(function(ctx) { genericFill(ctx); });
    }

    // ── Internshala ───────────────────────────────────────────────────────────
    else if (host.includes('internshala.')) {
        ctxs.forEach(function(ctx) {
            selectorFill(ctx, [
                [['input[name*="name" i]'],    u.name],
                [['input[name*="email" i]'],   u.email],
                [['input[name*="phone" i]'],   u.phone],
                [['textarea[name*="cover" i]', 'textarea[name*="sop" i]',
                  'textarea[placeholder*="cover" i]', 'textarea'], u.coverLetter],
            ]);
            genericFill(ctx);
        });
    }

    // ── Generic fallback (any other site) ────────────────────────────────────
    else {
        ctxs.forEach(function(ctx) { genericFill(ctx); });
    }

    // ════════════════════════════════════════════════════════════════════════════
    // GENERIC FILL — broad keyword scoring, used as fallback everywhere
    // ════════════════════════════════════════════════════════════════════════════
    function genericFill(ctx) {
        var maps = [
            { keys: ['firstname','givenname','fname','first_name','given_name'],  val: u.firstName   },
            { keys: ['lastname','familyname','lname','last_name','family_name','surname'], val: u.lastName },
            { keys: ['fullname','full_name','yourname','myname','applicant','candidate',
                      'legalname','legal_name'],                                  val: u.name        },
            { keys: ['email','emailid','emailaddr','email_id'],                   val: u.email       },
            { keys: ['phone','phoneno','phonenumber','mobile','mobileno','cellphone',
                      'contactno','contact_number','tel'],                        val: u.phone       },
            { keys: ['linkedin','linkedinurl','linkedin_url','linkedinprofile'],  val: u.linkedin    },
            { keys: ['experience','totalexp','yearsofexp','yoe','workexp','total_experience',
                      'expinyears','years_of_experience','totalyears','workyears'], val: u.experience  },
            { keys: ['currentctc','currentpackage','currentsalary','current_ctc','current_salary',
                      'presentctc','presentsalary','currentannual'],              val: u.currentCTC  },
            { keys: ['expectedctc','expectedpackage','expectedsalary','expected_ctc',
                      'expected_salary','desiredsalary','desired_salary','expectedannual'],
                                                                                  val: u.expectedCTC },
            { keys: ['notice','noticeperiod','notice_period','availabilitytojoin',
                      'joining','joiningtime','joiningperiod'],                   val: u.noticePeriod },
            { keys: ['skills','keyskills','key_skills','skillset','skill_set',
                      'technicalskills','tech_skills','corecompetencies'],        val: u.skills      },
            { keys: ['location','city','currentlocation','current_location','preferred_location',
                      'preferredlocation','worklocation','work_location','jobcity'],
                                                                                  val: u.location    },
            { keys: ['gender','sex'],                                             val: u.gender      },
            { keys: ['remote','workanywhere','openstoremote','remotework'],       val: u.remoteOK    },
            { keys: ['coverletter','cover_letter','coveringletter','whyus','aboutyou',
                      'motivation','whyyou','summary','message','note','additional',
                      'additionalnotes','anything_else'],                         val: u.coverLetter },
            { keys: ['jobtitle','currenttitle','currentdesig','currentdesignation',
                      'currentrole','desiredposition','position','designation'],  val: u.role        },
            { keys: ['name'], val: u.name }, // broadest — last
        ];

        var inputs = qsa(ctx,
            'input:not([type="hidden"]):not([type="submit"]):not([type="button"])' +
            ':not([type="checkbox"]):not([type="radio"]):not([type="file"])' +
            ':not([type="password"]):not([type="search"]),' +
            'textarea, select'
        );

        inputs.forEach(function(el) {
            if (!isVisible(el)) return;
            for (var i = 0; i < maps.length; i++) {
                var m = maps[i];
                if (!m.val) continue;
                if (score(el, m.keys)) {
                    tryFill(el, m.val);
                    break;
                }
            }
        });
    }

    return JSON.stringify(filled.length > 0 ? filled : []);

    } catch(outerErr) {
        // Always return valid JSON — never let an exception propagate
        return JSON.stringify([{ label: 'debug_error', value: outerErr.toString() }]);
    }
    })();
    """
}

// MARK: - Submit JS

let submitFormScript = """
(function() {
    try {
        var btn = document.querySelector('button[type="submit"], input[type="submit"]');
        if (!btn) {
            var all = Array.from(document.querySelectorAll('button, [role="button"], a'));
            var kws = ['submit application','apply now','apply','send application',
                       'submit resume','continue','next','send'];
            for (var k of kws) {
                btn = all.find(function(b) {
                    return (b.innerText || b.getAttribute('aria-label') || '')
                        .trim().toLowerCase().includes(k);
                });
                if (btn) break;
            }
        }
        if (btn) { btn.click(); return 'clicked:' + (btn.innerText || '').trim(); }
        var form = document.querySelector('form');
        if (form) { form.submit(); return 'form_submitted'; }
        return 'not_found';
    } catch(e) { return 'error:' + e.toString(); }
})();
"""

// MARK: - Auto-login JS (runs on every page load)

func buildAutoLoginJS(email: String) -> String {
    let safeEmail = email
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
    return """
    (function() {
    try {
        var email = "\(safeEmail)";
        if (!email) return;

        function setVal(el, v) {
            if (!el) return;
            try {
                var d = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value');
                if (d && d.set) d.set.call(el, v); else el.value = v;
            } catch(e) { el.value = v; }
            ['input','change','blur'].forEach(function(t) {
                try { el.dispatchEvent(new Event(t, { bubbles: true })); } catch(e) {}
            });
        }

        // Fill email/username on any login-looking page
        var emailSels = [
            'input[type="email"]',
            'input[name*="email" i]', 'input[id*="email" i]',
            'input[placeholder*="email" i]',
            'input[autocomplete="email"]', 'input[autocomplete="username"]',
            'input[name*="username" i]', 'input[id*="username" i]',
            'input[name*="user" i]:not([name*="last" i]):not([name*="first" i])',
        ];
        for (var s of emailSels) {
            try {
                var el = document.querySelector(s);
                if (el && el.offsetParent !== null && !el.value) { setVal(el, email); }
            } catch(e) {}
        }

        // Click Google SSO if present
        var googleKws = ['sign in with google','continue with google','login with google',
                         'google sign in','sign up with google','google'];
        var allBtns = Array.from(document.querySelectorAll('button,[role="button"],a,[class*="google" i]'));
        for (var kw of googleKws) {
            var btn = allBtns.find(function(b) {
                var txt = (b.innerText || b.getAttribute('aria-label') || b.title || '').toLowerCase();
                return txt.includes(kw);
            });
            if (btn) { try { btn.click(); } catch(e) {} break; }
        }
    } catch(e) {}
    })();
    """
}
