import SwiftUI

struct OnboardingPage2: View {
    @Binding var page: Int

    private let bgColor = Color(hex: "#C7C9CC")
    private let skipColor = Color(hex: "#3D538B")
    private let subtitleColor = Color(hex: "#6F7174")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation {
                            page = 1 
                        }
                    }
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(skipColor)
                    .padding(.trailing, 20)
                }
                .padding(.top, 18)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEEP WORK,\nDELIVERED")
                        .font(sfProBold(36))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(hex: "#2E3B6D"))

                    Text("Optimize your study sessions\nwith the pomodero Techniques.")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(subtitleColor)
                        .padding(.leading, 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 40)
                .padding(.bottom, 100)

                Image("onboarding_2")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 340)

                Spacer()

                HStack(spacing: 18) {
                    Button {
                            withAnimation(.easeInOut) {
                                page = 0
                            }
                        } label: {
                            Circle()
                                .frame(width: 14, height: 14)
                                .foregroundColor(Color.black.opacity(0.4))
                        }

                    Capsule()
                        .frame(width: 35, height: 14)
                        .foregroundColor(Color.black.opacity(0.28))

                    Button {
                        withAnimation(.easeInOut) {
                            page = 2
                        }
                    } label: {
                        Circle()
                            .frame(width: 14, height: 14)
                            .foregroundColor(Color.black.opacity(0.4))
                    }
                }
                .padding(.bottom, 36)
            }
        }
    }
}

struct OnboardingPage2_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPage2(page: .constant(1))
            .previewDevice("iPhone 14 Pro")
    }
}
