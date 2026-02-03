import SwiftUI

struct RootView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var flow: AppFlow = .splash

    var body: some View {
        ZStack {
            switch flow {

            case .splash:
                SplashView {
                    withAnimation {
                        flow = hasSeenOnboarding ? .permissions : .onboarding
                    }
                }

            case .onboarding:
                OnboardingContainer {
                    hasSeenOnboarding = true
                    withAnimation {
                        flow = .permissions
                    }
                }

            case .permissions:
                CameraPermissionView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: flow)
    }
}
