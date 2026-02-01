import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct OnboardingPage1: View {

    private let bgColor = Color(hex: "#2D3135")
    private let subtitleColor = Color(white: 0.85)
    private let accentLightBlue = Color(red: 133/255, green: 199/255, blue: 216/255)
    private let skipColor = Color(hex: "#51ADC7")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(skipColor)
                    .padding(.trailing, 24)
                }
                .padding(.top, 8)

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
                        .frame(width: 44, height: 12)
                        .foregroundColor(Color.white.opacity(0.25))

                    Circle()
                        .frame(width: 14, height: 14)
                        .foregroundColor(Color.white.opacity(0.2))

                    Circle()
                        .frame(width: 14, height: 14)
                        .foregroundColor(Color.white.opacity(0.2))
                }
                .padding(.bottom, 36)
            }
        }
    }
}

struct OnboardingPage1_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPage1()
            .previewDevice("iPhone 14 Pro")
    }
}
