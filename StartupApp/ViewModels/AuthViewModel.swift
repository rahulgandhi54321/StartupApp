import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var user: GoogleUserMock?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        GoogleSignInManager.shared.restorePreviousSignIn { [weak self] user in
            if let user = user {
                self?.user = user
                self?.isSignedIn = true
            }
        }
    }

    func signInWithGoogle(presenting viewController: UIViewController) {
        isLoading = true
        errorMessage = nil
        GoogleSignInManager.shared.signIn(presenting: viewController) { [weak self] user, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.user = user
                self?.isSignedIn = true
            }
        }
    }

    func signOut() {
        GoogleSignInManager.shared.signOut()
        user = nil
        isSignedIn = false
    }

    var displayName: String { user?.name ?? "User" }
    var email: String { user?.email ?? "" }
    var avatarURL: URL? { user?.avatarURL }
}
