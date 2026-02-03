import SwiftUI

struct ModeSelectionView: View {

    private let bgColor = Color(hex: "#2D3135")
    private let accentColor = Color(hex: "#B084B0")
    private let cardColor = Color(hex: "#49494A")

    private let imageColumnWidth: CGFloat = 140

    @State private var goToDriverMode = false
    @State private var goToStudyMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                VStack(spacing: 28) {

                    Spacer(minLength: 40)

                    Text("What do you want to do now?")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    modeCard(
                        imageView:
                            Image("driver_car")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: imageColumnWidth * 0.7,
                                    height: imageColumnWidth * 0.7
                                )
                                .offset(y: -5),
                        title: "Stay alert while\ndriving",
                        points: [
                            "Real-time alerts",
                            "Eye detection",
                            "Safety-first"
                        ],
                        buttonTitle: "Driver Mode",
                        action: {
                            goToDriverMode = true
                        }
                    )

                    modeCard(
                        imageView:
                            Image("study")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: imageColumnWidth * 1.1,
                                    height: imageColumnWidth * 1.1
                                )
                                .offset(y: 8),
                        title: "Stay focused while\nstudying",
                        points: [
                            "Real-time movement",
                            "Laziness detection",
                            "Safety-first"
                        ],
                        buttonTitle: "Study Mode",
                        action: {
                            goToStudyMode = true
                        }
                    )

                    Spacer()
                }
                .padding(.horizontal, 20)
            }

            .navigationDestination(isPresented: $goToDriverMode) {
                DriverDetectionView()
            }
            .navigationDestination(isPresented: $goToStudyMode) {
                Text("Study Mode Coming Soon")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bgColor)
            }
        }
    }

    private func modeCard<ImageView: View>(
        imageView: ImageView,
        title: String,
        points: [String],
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {

        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {

                imageView
                    .frame(
                        width: imageColumnWidth,
                        height: imageColumnWidth,
                        alignment: .center
                    )

                VStack(alignment: .leading, spacing: 8) {

                    Text(title)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(accentColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(points, id: \.self) { point in
                            Text("• \(point)")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 12)
            }

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(cardColor)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12))
        )
    }
}

struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView()
            .previewDevice("iPhone 14 Pro")
    }
}
