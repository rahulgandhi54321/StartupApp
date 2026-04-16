import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0F0F1A").ignoresSafeArea()

            // Background blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "6C63FF").opacity(0.25))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -60, y: -40)

                Circle()
                    .fill(Color(hex: "A78BFA").opacity(0.2))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: geo.size.width - 160, y: geo.size.height - 300)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Logo + headline
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6C63FF"), Color(hex: "A78BFA")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "sparkles")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Sign in to Job Hunter AI")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Join thousands building the future")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                .padding(.bottom, 56)

                // Sign-in buttons
                VStack(spacing: 14) {
                    GoogleSignInButton()
                        .environmentObject(authVM)

                    HStack {
                        Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
                        Text("or")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.horizontal, 12)
                        Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 14) {
                        SocialIconButton(icon: "apple.logo", label: "Apple") {}
                        SocialIconButton(icon: "envelope.fill", label: "Email") {}
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // Error message
                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "EF4444"))
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                }

                Text("By continuing, you agree to our **Terms of Service** and **Privacy Policy**")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 36)
            }
        }
    }
}

struct GoogleSignInButton: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Button {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            authVM.signInWithGoogle(presenting: root)
        } label: {
            HStack(spacing: 12) {
                if authVM.isLoading {
                    ProgressView()
                        .tint(.black)
                        .frame(width: 22, height: 22)
                } else {
                    GoogleLogo()
                        .frame(width: 22, height: 22)
                }
                Text(authVM.isLoading ? "Signing in..." : "Continue with Google")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .disabled(authVM.isLoading)
    }
}

struct GoogleLogo: View {
    var body: some View {
        Text("G")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "4285F4"), Color(hex: "34A853"), Color(hex: "EA4335")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct SocialIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
