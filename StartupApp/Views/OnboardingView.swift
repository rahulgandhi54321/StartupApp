import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showSignIn = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "Welcome to Job Hunter AI",
            subtitle: "Your all-in-one platform to launch, grow, and scale your ideas.",
            gradient: [Color(hex: "6C63FF"), Color(hex: "A78BFA")]
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Growth",
            subtitle: "Real-time analytics and insights to keep you ahead of the curve.",
            gradient: [Color(hex: "F59E0B"), Color(hex: "EF4444")]
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "Collaborate Seamlessly",
            subtitle: "Invite your team and build something extraordinary together.",
            gradient: [Color(hex: "10B981"), Color(hex: "3B82F6")]
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: currentPage)

            VStack(spacing: 0) {
                Spacer()

                // Page icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 56, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 48)

                // Text
                VStack(spacing: 16) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .id("title_\(currentPage)")

                    Text(pages[currentPage].subtitle)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .id("subtitle_\(currentPage)")
                }
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(.white.opacity(index == currentPage ? 1 : 0.4))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.bottom, 40)

                // Buttons
                VStack(spacing: 12) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(pages[currentPage].gradient[0])
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button { showSignIn = true } label: {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(pages[currentPage].gradient[0])
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    if currentPage < pages.count - 1 {
                        Button {
                            showSignIn = true
                        } label: {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView()
        }
    }
}
