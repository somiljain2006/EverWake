import SwiftUI
import AVFoundation

struct DriverDetectionView: View {

    @Environment(\.dismiss) var dismiss
    
    @StateObject private var detector = EyeDetector()
    @StateObject private var pomodoroTimer = PomodoroTimer()
    
    @State private var showingAlert = false
    @State private var isRestarting = false
    @State private var showAnalytics = false
    @State private var tripAlerts = 0
    @State private var alertTimer: Timer?
    @State private var alertPlayer: AVAudioPlayer?
    
    @AppStorage("profileImageData") private var profileImageData: Data?

    private let bgColor = Color(hex: "#2D3135")
    private let buttonColor = Color(hex: "#49494A")
    
    let launchedFromStudy: Bool
    let autoStart: Bool
    let pomodoroDuration: Int?

    init(detector: EyeDetector? = nil,
         autoStart: Bool = false,
         pomodoroDuration: Int? = nil,
         launchedFromStudy: Bool = false) {
        self.autoStart = autoStart
        self.pomodoroDuration = pomodoroDuration
        self.launchedFromStudy = launchedFromStudy
    }

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
                        Button(action: {
                            stopDetectionAndDismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 24)
                                .padding(.top, 20)
                                .shadow(radius: 2)
                        }
                    }

                    Spacer()

                    if !isActiveState || detector.isRunning {
                        HStack(spacing: 12) {
                            
                            if pomodoroDuration != nil {
                                PomodoroTimerBadge(
                                    timeText: pomodoroTimer.formattedTime(),
                                    isRunning: pomodoroTimer.isRunning
                                )
                                .padding(.top, 6)
                                .padding(.trailing, 16)
                            }
                            
                            if !isActiveState {
                                NavigationLink(destination: DriverProfileView(onExit: {
                                    stopDetectionForProfile()
                                })) {
                                    profileImage
                                        .frame(width: 45, height: 45)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                        .padding(.trailing, 24)
                                        .padding(.top, 25)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
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
                    stopAlertSound()
                    withAnimation(.easeOut(duration: 0.1)) {
                        showingAlert = false
                    }
                    startDetectorSafe()
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            if showAnalytics {
                analyticsView
                    .zIndex(200)
            }
        }
        .onAppear {
            configureAudioSession()
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
                tripAlerts += 1
                showingAlert = true
                playAlertSound()
                stopDetectorSafe()
            }
        }
        .task(id: autoStart) {
            if autoStart && !detector.isRunning {
                detector.resetTrip()
                startDetectorSafe()
                
                if let duration = pomodoroDuration {
                    pomodoroTimer.start(seconds: duration)
                }
            }
        }
    }
    
    private func startDetectorSafe() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.detector.start()
        }
    }
    
    private func stopDetectorSafe() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.detector.stop()
        }
    }
    
    private func toggleDetection() {
        withAnimation {
            if detector.isRunning {
                stopAlertSound()
                stopDetectorSafe()
                pomodoroTimer.stop()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut) {
                        showAnalytics = true
                    }
                }
            } else {
                tripAlerts = 0
                detector.resetTrip()
                startDetectorSafe()
                if let duration = pomodoroDuration {
                    pomodoroTimer.reset(seconds: duration, startImmediately: true)
                }
            }
        }
    }
    
    private func stopDetectionAndDismiss() {
        stopDetectorSafe()
        pomodoroTimer.stop()
        dismiss()
    }
    
    private func stopDetectionForProfile() {
        stopDetectorSafe()
        pomodoroTimer.stop()
    }

    private var profileImage: some View {
        Group {
            if let data = profileImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        }
    }

    private var analyticsView: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text("Session Summary")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)

                VStack(spacing: 18) {
                    HStack {
                        Text("Focus Time")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.6))
                        Spacer()
                        Text(sessionTimeText(from: detector.totalTripDuration))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    HStack {
                        Text("Drowsiness Alerts")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.6))
                        Spacer()
                        Text("\(tripAlerts)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                Button {
                    if launchedFromStudy {
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    } else {
                        withAnimation {
                            showAnalytics = false
                        }
                    }
                } label: {
                    Text("Back to Dashboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#6CB8C9"))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color(hex: "#49494A"))
                        .cornerRadius(12)
                        .shadow(radius: 6)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func sessionTimeText(from duration: TimeInterval) -> String {
        let secs = Int(round(duration))
        if secs >= 60 {
            let minutes = secs / 60
            return "\(minutes) min"
        } else {
            return "\(secs) sec"
        }
    }
    
    private func playAlertSound() {
        stopAlertSound()

        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            print("❌ alarm.wav not found in bundle")
            return
        }

        do {
            alertPlayer = try AVAudioPlayer(contentsOf: url)
            alertPlayer?.volume = 1.0
            alertPlayer?.numberOfLoops = -1
            alertPlayer?.prepareToPlay()
            alertPlayer?.play()
        } catch {
            print("❌ Failed to play alarm:", error)
        }
    }
    
    private func stopAlertSound() {
        alertPlayer?.stop()
        alertPlayer = nil
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ Audio session setup failed:", error)
        }
    }

}
