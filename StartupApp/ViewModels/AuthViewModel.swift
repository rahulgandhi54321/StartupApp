import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn    = false
    @Published var user: GoogleUserMock?
    @Published var isLoading     = false
    @Published var errorMessage: String?
    @Published var remoteProfile: SupabaseService.ProfileRow?
    @Published var remoteJobPref: SupabaseService.JobPrefRow?

    init() {
        GoogleSignInManager.shared.restorePreviousSignIn { [weak self] user in
            if let user = user { self?.user = user; self?.isSignedIn = true }
        }
    }

    func signInWithGoogle(presenting vc: UIViewController) {
        isLoading = true; errorMessage = nil
        GoogleSignInManager.shared.signIn(presenting: vc) { [weak self] user, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let e = error { self?.errorMessage = e.localizedDescription; return }
                self?.user = user; self?.isSignedIn = true
            }
        }
    }

    func signOut() {
        GoogleSignInManager.shared.signOut()
        user = nil; remoteProfile = nil; remoteJobPref = nil; isSignedIn = false
    }

    /// Called once after sign-in so every tab has profile data immediately.
    func loadUserData() async {
        guard remoteProfile == nil else { return }
        async let profile = SupabaseService.shared.fetchProfile(userId: userId)
        async let jobPref = SupabaseService.shared.fetchJobPref(userId: userId)
        remoteProfile = (try? await profile)
        remoteJobPref = (try? await jobPref)
    }

    var userId:      String { user?.email ?? "anonymous" }
    var displayName: String { user?.name  ?? "User" }
    var email:       String { user?.email ?? "" }
    var avatarURL:   URL?   { user?.avatarURL }
}
