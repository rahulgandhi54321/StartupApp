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

    var userId:      String { user?.email ?? "anonymous" }
    var displayName: String { user?.name  ?? "User" }
    var email:       String { user?.email ?? "" }
    var avatarURL:   URL?   { user?.avatarURL }
}
