import SwiftUI
import WebKit

/// Full-screen WebView for logging in to a job portal.
/// Uses the default (persistent) WKWebsiteDataStore so the session is saved
/// and reused every time the user opens that portal in JobWebView.
struct PortalLoginView: View {
    let portal: JobPortal
    @StateObject private var ctrl = PortalWebController()
    @ObservedObject private var store = ConnectedPortalsStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showConnectedBanner = false

    var body: some View {
        ZStack(alignment: .top) {
            PortalWebViewRepresentable(urlString: portal.loginURL, controller: ctrl)
                .ignoresSafeArea()

            // Progress bar
            if ctrl.progress < 1.0 {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color(hex: portal.color))
                        .frame(width: geo.size.width * ctrl.progress, height: 3)
                        .animation(.linear(duration: 0.15), value: ctrl.progress)
                }
                .frame(height: 3)
            }

            // Connected banner
            if showConnectedBanner {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "10B981"))
                        Text("\(portal.name) connected!").font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.black).padding(.horizontal, 20).padding(.vertical, 13)
                    .background(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                    .padding(.top, 12)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("Connect \(portal.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { ctrl.webView?.reload() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onReceive(ctrl.$currentURL) { url in
            guard let url = url else { return }
            let isLoggedIn = portal.homeHosts.contains(where: { url.lowercased().contains($0.lowercased()) })
            if isLoggedIn && !store.isConnected(portal) {
                store.markConnected(portal)
                withAnimation { showConnectedBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    dismiss()
                }
            }
        }
    }
}

// ── Controller ────────────────────────────────────────────────────────────────

class PortalWebController: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var progress:    Double  = 0
    @Published var currentURL:  String? = nil
    var webView: WKWebView?

    private var obs: NSKeyValueObservation?

    func attach(_ wv: WKWebView) {
        webView = wv
        wv.navigationDelegate = self
        obs = wv.observe(\.estimatedProgress) { [weak self] wv, _ in
            DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.progress    = 1.0
            self.currentURL  = webView.url?.absoluteString
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async { self.currentURL = webView.url?.absoluteString }
    }
}

// ── Representable ─────────────────────────────────────────────────────────────

struct PortalWebViewRepresentable: UIViewRepresentable {
    let urlString:  String
    let controller: PortalWebController

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()  // persistent cookies
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        controller.attach(wv)
        if let url = URL(string: urlString) { wv.load(URLRequest(url: url)) }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
