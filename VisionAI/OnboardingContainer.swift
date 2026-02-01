import SwiftUI
import Combine

struct OnboardingContainer: View {
    @State private var page = 0
    private let totalPages = 3

    private let timer = Timer.publish(
        every: 3,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        TabView(selection: $page) {
            OnboardingPage1(page: $page)
                .tag(0)

            OnboardingPage2(page: $page)
                .tag(1)

            OnboardingPage3(page: $page)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onReceive(timer) { _ in
            withAnimation(.easeInOut) {
                if page < totalPages - 1 {
                    page += 1
                }
            }
        }
    }
}
