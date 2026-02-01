import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    @State private var eyeOpacity: Double = 0.0
    @State private var eyeSize: CGFloat = 120
    
    @State private var taglineOpacity: Double = 0.0
    @State private var taglineOffsetY: CGFloat = 6
    @State private var taglineOffsetX: CGFloat = 0
    
    @State private var moveEyeToLeft = false
    @State private var textRevealProgress: CGFloat = 0
    
    let titleText = "VisionAI"

    private func titleStyle(for char: Character) -> AnyShapeStyle {
        if char == "A" || char == "I" {
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 76/255, green: 142/255, blue: 194/255), location: 0.1107),
                        .init(color: Color(red: 74/255, green: 173/255, blue: 195/255), location: 0.7283)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color.black)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()

                HStack(spacing: moveEyeToLeft ? -18 : 0) {
                    
                    // Eye logo
                    Image("eye_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(eyeSize / 120)
                        .opacity(eyeOpacity)
                    
                    VStack(alignment: .leading, spacing: -1) {
                        
                        HStack(spacing: 0) {
                            ForEach(Array(titleText.enumerated()), id: \.offset) { _, char in
                                Text(String(char))
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(titleStyle(for: char))
                            }
                        }
                        .fixedSize()
                        .mask(
                            GeometryReader { geo in
                                Rectangle()
                                    .frame(width: geo.size.width * textRevealProgress)
                            }
                        )

                        .fixedSize(horizontal: true, vertical: false)

                        Text("\"Stay Awake. Stay Focused.\"")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .opacity(taglineOpacity)
                            .offset(x: 7, y: taglineOffsetY)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(width: moveEyeToLeft ? nil : 0, alignment: .leading)
                    .clipped()
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    eyeOpacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(
                        .interpolatingSpring(
                            mass: 0.9,
                            stiffness: 80,
                            damping: 18,
                            initialVelocity: 0
                        )
                    ) {
                        moveEyeToLeft = true
                        eyeSize = 84
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.7)) {
                        textRevealProgress = 1
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        taglineOpacity = 1.0
                        taglineOffsetY = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeInOut) {
                        onFinished()
                    }
                }
            }
        }
    }
}
