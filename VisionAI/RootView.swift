import SwiftUI

struct RootView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isSetupComplete") private var isSetupComplete = false
    
    @State private var flow: AppFlow = .splash

    var body: some View {
        ZStack {
            switch flow {

            case .splash:
                SplashView {
                    withAnimation {
                        if isSetupComplete {
                            flow = .modeSelection
                        } else if hasSeenOnboarding {
                            flow = .permissions
                        } else {
                            flow = .onboarding
                        }
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

            case .modeSelection:
                ModeSelectionView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: flow)
    }
}
