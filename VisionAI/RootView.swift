import SwiftUI
struct RootView: View {
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingPage1()
                    .transition(.opacity)
            } else {
                SplashView {
                    showOnboarding = true
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
    }
}
