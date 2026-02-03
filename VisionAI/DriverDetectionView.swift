import SwiftUI

struct DriverDetectionView: View {

    private let bgColor = Color(hex: "#2D3135")
    private let buttonColor = Color(hex: "#49494A")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()

                    Button {
                        print("Profile / settings tapped")
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))

                            Image("person")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .scaleEffect(2.5)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 62)
                }

                Spacer()
            }
            .ignoresSafeArea(edges: .top)

            VStack {

                Spacer()

                Button {
                    print("Camera button tapped")
                } label: {
                    ZStack {

                        // Background image inside circle
                        Image("camera-background")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .scaleEffect(1.5)
                            .clipped()
                            .clipShape(Circle())

                        // Glass gradient overlay
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 130, height: 130)

                        // White stroke
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 130, height: 130)

                        Image("camera")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.white) // works if SVG is template
                            .shadow(radius: 4)
                    }
                }

                Spacer()

                Button {
                    print("Start detection")
                } label: {
                    Text("Start Detection")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(buttonColor)
                        .cornerRadius(16)
                        .shadow(radius: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct DriverDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        DriverDetectionView()
            .previewDevice("iPhone 14 Pro")
    }
}
