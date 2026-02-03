import SwiftUI

struct OnboardingPage1: View {
    @Binding var page: Int
    let onFinish: () -> Void

    private let bgColor = Color(hex: "#2D3135")
    private let subtitleColor = Color(hex: "#D9D9D9")
    private let accentLightBlue = Color(hex: "#85C7D8")
    private let skipColor = Color(hex: "#51ADC7")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onFinish()
                    }
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(skipColor)
                    .padding(.trailing, 24)
                }
                .padding(.top, 18)

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 16) {
                    Text("FOCUS ON\nTHE ROAD")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)

                    Text("Drive safely with intelligent,\ndistraction free navigation.")
                        .font(.system(size: 17))
                        .foregroundColor(subtitleColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 54)

                Image("onboarding_1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 24)
                    .padding(.top, 80)

                HStack(spacing: 14) {
                    Capsule()
                        .frame(width: 35, height: 12)
                        .foregroundColor(Color.white.opacity(0.25))

                    Button {
                        withAnimation(.easeInOut) {
                            page = 1  
                        }
                    } label: {
                        Circle()
                            .frame(width: 14, height: 14)
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    Button {
                            withAnimation(.easeInOut) {
                                page = 2
                            }
                        } label: {
                            Circle()
                                .frame(width: 14, height: 14)
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                }
                .padding(.bottom, 36)

            }
        }
    }
}

struct OnboardingPage1_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPage1(
            page: .constant(0),
            onFinish: {}
        )
        .previewDevice("iPhone 14 Pro")
    }
}
