import SwiftUI
import AVFoundation

struct DriverDetectionView: View {

    @Environment(\.dismiss) var dismiss
    @StateObject private var detector = EyeDetector()
    @State private var showingAlert = false
    @State private var isRestarting = false

    private let bgColor = Color(hex: "#2D3135")
    private let buttonColor = Color(hex: "#49494A")

    private var isActiveState: Bool {
        return detector.isRunning || showingAlert || isRestarting
    }

    var body: some View {
        ZStack {
            if detector.isRunning {
                ZStack {
                    CameraPreview(session: detector.session)
                        .ignoresSafeArea()

                    if !detector.isRunning {
                        bgColor
                            .ignoresSafeArea()
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.0)
                            )
                    }
                }
            } else {
                bgColor.ignoresSafeArea()
            }

            VStack {
                HStack {
                    if detector.isRunning {
                        if detector.closedDuration <= 5.0 {
                            Image("eyes-wide")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .padding(.leading, 18)
                                .shadow(radius: 2)
                                .transition(.opacity)
                        }
                    } else if !isActiveState {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 24)
                                .padding(.top, 20)
                                .shadow(radius: 2)
                        }
                    }

                    Spacer()

                    if !isActiveState {
                        Image("person")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .padding(.trailing, 24)
                            .shadow(radius: 2)
                            .padding(.top, 25)
                    }
                }
                .padding(.top, -10)
                .offset(y: -5)

                Spacer()

                if !isActiveState {
                    ZStack {
                        Image("camera-background")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 220)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.white)
                            )
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 175, height: 175)
                            .shadow(color: .white.opacity(0.5), radius: 10)
                            .offset(x: -1.5)
                    }
                    .padding(.bottom, 10)

                    Text("Ready to Start")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }

                Spacer()

                Button(action: toggleDetection) {
                    Text(isActiveState ? "Stop Detection" : "Start Detection")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isActiveState ? Color.red.opacity(0.9) : buttonColor)
                        .cornerRadius(14)
                        .shadow(radius: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(showingAlert ? 0 : 1)
            }

            if showingAlert {
                WakeUpScreen {
                    withAnimation(.easeOut(duration: 0.1)) {
                        showingAlert = false
                    }
                    detector.start()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: detector.isRunning) { _, newValue in
            if newValue {
                isRestarting = false
            }
        }
        .onReceive(detector.$closedDuration) { duration in
            if duration > 5.00 && !showingAlert {
                print("🚨 Eyes closed for \(duration)s — TRIGGER ALARM")
                showingAlert = true
                detector.stop()
            }
        }
    }

    private func toggleDetection() {
        withAnimation {
            if detector.isRunning {
                detector.stop()
            } else {
                detector.start()
            }
        }
    }
}
