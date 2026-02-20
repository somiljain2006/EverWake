import SwiftUI
import AVFoundation
import Combine
import AVKit

struct DriverDetectionView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var detector = EyeDetector()
    @StateObject private var pomodoroTimer = PomodoroTimer()
    
    @State private var isBreakActive = false
    @State private var breakTimeRemaining = 0
    @State private var breakTimerObj: Timer?
    @State private var showingAlert = false
    @State private var isRestarting = false
    @State private var showAnalytics = false
    @State private var tripAlerts = 0
    @State private var alertPlayer: AVAudioPlayer?
    @State private var dragOffset: CGFloat = 0
    @State private var pipController: AVPictureInPictureController?
    @State private var pipCoordinator = PiPCoordinator()
    @State private var isPiPActive = false

    @AppStorage("profileImageData") private var profileImageData: Data?
    @AppStorage("studyAlertSound") private var studyAlertSoundId: String = "bell"

    private let bgColor = Color(hex: "#2D3135")
    private let buttonColor = Color(hex: "#49494A")
    private let accentColor = Color(hex: "#8B8CFB")
    
    let launchedFromStudy: Bool
    let autoStart: Bool
    let pomodoroDuration: Int?
    let breakDuration: Int?

    init(detector: EyeDetector? = nil,
         autoStart: Bool = false,
         pomodoroDuration: Int? = nil,
         breakDuration: Int? = nil,
         launchedFromStudy: Bool = false) {
        self.autoStart = autoStart
        self.pomodoroDuration = pomodoroDuration
        self.breakDuration = breakDuration
        self.launchedFromStudy = launchedFromStudy
    }

    private var isActiveState: Bool {
        return detector.isRunning || showingAlert || isRestarting
    }

    var body: some View {
        ZStack {
            mainDetectionContent
                .blur(radius: isBreakActive ? 15 : 0)
                .animation(.easeInOut(duration: 0.5), value: isBreakActive)

            if showingAlert {
                WakeUpScreen {
                    stopAlertSound()
                    detector.acknowledgeAlertAndReset()
                    withAnimation(.easeOut(duration: 0.1)) {
                        showingAlert = false
                    }
                    startDetectorSafe()
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            if isBreakActive {
                breakView
                    .zIndex(150)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            if showAnalytics {
                analyticsView
                    .zIndex(200)
            }
        }
        .offset(x: dragOffset)
        .animation(.interactiveSpring(), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard canSwipeBack else { return }
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    guard canSwipeBack else {
                        dragOffset = 0
                        return
                    }

                    if value.translation.width > 120 {
                        stopDetectionAndDismiss()
                    }

                    dragOffset = 0
                }
        )
        .onAppear {
            configureAudioSession()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background,
               detector.isRunning,
               let controller = pipController,
               controller.isPictureInPicturePossible {

                controller.startPictureInPicture()
            }

            if phase == .active {
                pipController?.stopPictureInPicture()
            }
        }
        .onChange(of: detector.hasRenderedFirstFrame) { _, rendered in
            if rendered { setupPiPIfPossible() }
        }
        .onChange(of: detector.isRunning) { _, running in
            if !running {
                pipController?.stopPictureInPicture()
                pipController = nil
                isRestarting = false
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: pomodoroTimer.remainingSeconds) { _, newValue in
            if pomodoroDuration != nil &&
               newValue == 0 &&
               !isBreakActive &&
               !showAnalytics {

                startBreakMode()
            }
        }
        .onReceive(detector.$closedDuration) { duration in
            if duration > 2.5 && !showingAlert {
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
    
    private var mainDetectionContent: some View {
        let det = detector
        return ZStack {
            PiPVideoView(pipLayer: detector.activePipLayer)
                .ignoresSafeArea()
                .opacity(detector.isRunning ? 1 : 0)
            if det.isRunning {
                CameraPreview(session: det.session)
                    .ignoresSafeArea()
            } else {
                bgColor.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.0)
            }

            VStack {
                HStack {
                    if det.isRunning {
                        if det.closedDuration <= 2.5 {
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

                    if !isActiveState || det.isRunning {
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
                                NavigationLink(
                                    destination: DriverProfileView(
                                        showStudyOptions: launchedFromStudy,
                                        onExit: {
                                            stopDetectionForProfile()
                                        }
                                    )
                                ) {
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
        }
    }
    
    private var breakView: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("Break Time")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Text(formatBreakTime(breakTimeRemaining))
                    .font(.system(size: 80, weight: .light))
                    .fontDesign(.rounded)
                    .foregroundColor(accentColor)
                    .shadow(color: accentColor.opacity(0.3), radius: 10)
                
                Text("Relax and recharge your mind.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 10)
                
                Spacer()
                Button(action: stopBreakAndExit) {
                    Text("Exit to Dashboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(buttonColor)
                        .cornerRadius(14)
                        .shadow(radius: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
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

    private var profileImage: some View {
        Group {
            if let data = profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Image(systemName: "person.fill").resizable().scaledToFit().padding(8)
            }
        }
    }

    func setupPiPIfPossible() {
        guard
            AVPictureInPictureController.isPictureInPictureSupported(),
            pipController == nil
        else { return }

        let layer = detector.activePipLayer
        layer.videoGravity = .resizeAspectFill

        let controller = AVPictureInPictureController(
            contentSource: .init(
                sampleBufferDisplayLayer: layer,
                playbackDelegate: pipCoordinator
            )
        )
        controller.delegate = pipCoordinator
        controller.canStartPictureInPictureAutomaticallyFromInline = true

        pipCoordinator.onStart = { DispatchQueue.main.async { self.isPiPActive = true } }
        pipCoordinator.onStop  = { DispatchQueue.main.async { self.isPiPActive = false } }
        pipController = controller
    }


    private func startDetectorSafe() {
        Task { @MainActor in detector.start() }
    }

    private func stopDetectorSafe() {
        Task { @MainActor in detector.stop() }
    }

    private func toggleDetection() {
        withAnimation {
            if detector.isRunning {
                stopAlertSound()
                stopDetectorSafe()
                pomodoroTimer.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut) { showAnalytics = true }
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

    private func startBreakMode() {
        guard let bDuration = breakDuration else { return }
        stopDetectorSafe()
        pomodoroTimer.stop()
        withAnimation {
            isBreakActive = true
            breakTimeRemaining = bDuration
        }
        playAlertOnce()
        breakTimerObj?.invalidate()
        breakTimerObj = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if breakTimeRemaining > 0 {
                    breakTimeRemaining -= 1
                } else {
                    breakTimerObj?.invalidate()
                    handleBreakEnd()
                }
            }
        }
    }

    private func handleBreakEnd() {
        playAlertOnce()
        withAnimation { isBreakActive = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            startDetectorSafe()
            if let duration = pomodoroDuration {
                pomodoroTimer.reset(seconds: duration, startImmediately: true)
            }
        }
    }

    private func stopBreakAndExit() {
        breakTimerObj?.invalidate()
        breakTimerObj = nil
        dismiss()
    }

    // MARK: - Audio

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .videoChat,
                options: [.mixWithOthers, .defaultToSpeaker, .duckOthers]
            )
            try session.setActive(true)
        } catch {
            print("❌ Audio session setup failed:", error)
        }
    }

    private func playAlertSound() {
        stopAlertSound()
        guard let url = alertSoundURL() else { return }
        do {
            alertPlayer = try AVAudioPlayer(contentsOf: url)
            alertPlayer?.numberOfLoops = -1
            alertPlayer?.volume = 1.0
            alertPlayer?.play()
        } catch {
            print("❌ Failed to play alert sound:", error)
        }
    }
    
    private func playAlertOnce() {
        stopAlertSound()
        guard let url = alertSoundURL() else { return }
        do {
            alertPlayer = try AVAudioPlayer(contentsOf: url)
            alertPlayer?.numberOfLoops = 0
            alertPlayer?.volume = 1.0
            alertPlayer?.play()
        } catch {
            print("❌ Failed to play one-shot alert sound:", error)
        }
    }

    private func alertSoundURL() -> URL? {
        if launchedFromStudy {
            if studyAlertSoundId == StudyAlertStorage.customSoundId {
                return StudyAlertStorage.customSoundURL
            }
            let file = studyAlertSounds.first(where: { $0.id == studyAlertSoundId })?.fileName ?? "study_bell"
            return Bundle.main.url(forResource: file, withExtension: "wav")
        }
        return Bundle.main.url(forResource: "alarm", withExtension: "wav")
    }

    private func stopAlertSound() {
        alertPlayer?.stop()
        alertPlayer = nil
    }

    private func sessionTimeText(from duration: TimeInterval) -> String {
        let secs = Int(round(duration))
        return secs >= 60 ? "\(secs / 60) min" : "\(secs) sec"
    }

    private func formatBreakTime(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private var canSwipeBack: Bool {
        !detector.isRunning &&
        !showingAlert &&
        !showAnalytics &&
        !isRestarting &&
        !isBreakActive 
    }
}
