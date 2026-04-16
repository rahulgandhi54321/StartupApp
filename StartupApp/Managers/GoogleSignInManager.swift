import SwiftUI

// Swap this file for the real GoogleSignIn SDK integration when ready.
// Replace GoogleUserMock with GIDGoogleUser and update signIn() to call
// GIDSignIn.sharedInstance.signIn(withPresenting:).

struct GoogleUserMock {
    let name: String
    let email: String
    let avatarURL: URL?
}

final class GoogleSignInManager {
    static let shared = GoogleSignInManager()
    private init() {}

    func signIn(presenting: UIViewController, completion: @escaping (GoogleUserMock?, Error?) -> Void) {
        // Simulates a 1-second network round-trip then returns a fake user.
        // Replace this body with the real GIDSignIn call.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let user = GoogleUserMock(
                name: "Rahul Gandhi",
                email: "rahul@example.com",
                avatarURL: URL(string: "https://ui-avatars.com/api/?name=Rahul+Gandhi&size=200&background=6C63FF&color=fff")
            )
            completion(user, nil)
        }
    }

    func signOut() {}

    func restorePreviousSignIn(completion: @escaping (GoogleUserMock?) -> Void) {
        completion(nil) // No persisted session in mock
    }
}
