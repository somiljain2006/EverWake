import SwiftUI
import AVFoundation
import Combine

struct DriverDetectionView: View {

    @Environment(\.dismiss) var dismiss
    
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
    @State private var isPaused = false
    @State private var hasAttemptedAutoStart = false
    
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
        // If we are about to auto-start, treat the view as active so buttons stay hidden
        let pendingAutoStart = autoStart && !hasAttemptedAutoStart
        return detector.isRunning || detector.isStarting || pendingAutoStart || showingAlert || isRestarting
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
            if autoStart && !hasAttemptedAutoStart {
                hasAttemptedAutoStart = true
                detector.resetTrip()
                startDetectorSafe()
                
                if let duration = pomodoroDuration {
                    pomodoroTimer.start(seconds: duration)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: detector.isRunning) { _, newValue in
            if newValue {
                isRestarting = false
            }
        }
        .onChange(of: pomodoroTimer.remainingSeconds) { _, newValue in
            if pomodoroDuration != nil &&
               newValue == 0 &&
               !isBreakActive &&
               !showAnalytics {

                startBreakMode()
            }
        }
        .onReceive(detector.$closedDuration) { duration in
            guard !isPaused else { return }
            if duration > 2.5 && !showingAlert {
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
    
    private var mainDetectionContent: some View {
        ZStack {
            if detector.isRunning || detector.isStarting || (autoStart && !hasAttemptedAutoStart) {
                ZStack {
                    if detector.isRunning && detector.session != nil {
                        CameraPreview(session: detector.session)
                            .ignoresSafeArea()
                    } else {
                        bgColor
                            .ignoresSafeArea()
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            )
                    }
                }
            } else {
                bgColor.ignoresSafeArea()
            }

            VStack {
                HStack(alignment: .top) {
                    if !isActiveState {
                        Button(action: {
                            stopDetectionAndDismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                                .padding(.top, 8)
                                .shadow(radius: 2)
                        }
                    } else {
                        Color.clear
                            .frame(width: 44, height: 44)
                            .padding(.leading, 8)
                            .padding(.top, 8)
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        if detector.isRunning && detector.closedDuration <= 2.5 {
                            Image("eyes-wide")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .shadow(radius: 2)
                                .transition(.opacity)
                        }

                        if pomodoroDuration != nil {
                            PomodoroTimerBadge(
                                timeText: pomodoroTimer.formattedTime(),
                                isRunning: pomodoroTimer.isRunning
                            )
                            .padding(.top, 2)
                        }
                    }
                    .padding(.top, 12)
                    .frame(minWidth: 0, maxWidth: .infinity)

                    Spacer()

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
                                .padding(.trailing, 16)
                                .padding(.top, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Color.clear
                            .frame(width: 45, height: 45)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)

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

                VStack(spacing: 14) {

                    if launchedFromStudy && detector.isRunning && !showingAlert {
                        Button {
                            withAnimation {
                                isPaused ? resumeDetection() : pauseDetection()
                            }
                        } label: {
                            Text(isPaused ? "Resume Detection" : "Pause Detection")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.9))
                                .cornerRadius(14)
                                .shadow(radius: 6)
                        }
                        .padding(.horizontal, 24)
                    }

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
                }
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
                
                Button {
                    stopBreakAndExit()
                } label: {
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

        withAnimation {
            isBreakActive = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.startDetectorSafe()
            
            if let duration = self.pomodoroDuration {
                self.pomodoroTimer.reset(seconds: duration, startImmediately: true)
            }
        }
    }
    
    private func stopBreakAndExit() {
        breakTimerObj?.invalidate()
        breakTimerObj = nil
        dismiss()
    }
    
    private func startDetectorSafe() {
        Task { @MainActor in
            detector.start()
        }
    }
    
    private func stopDetectorSafe() {
        Task { @MainActor in
            detector.stop()
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
    
    private func formatBreakTime(_ totalSeconds: Int) -> String {
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
    
    private func playAlertSound() {
        stopAlertSound()

        var url: URL?

        if launchedFromStudy {
            if studyAlertSoundId == StudyAlertStorage.customSoundId {
                url = StudyAlertStorage.customSoundURL
            } else {
                let file = studyAlertSounds
                    .first(where: { $0.id == studyAlertSoundId })?
                    .fileName ?? "study_bell"

                url = Bundle.main.url(forResource: file, withExtension: "wav")
            }
        } else {
            url = Bundle.main.url(forResource: "alarm", withExtension: "wav")
        }

        guard let soundURL = url else {
            print("❌ Alert sound not found")
            return
        }

        do {
            alertPlayer = try AVAudioPlayer(contentsOf: soundURL)
            alertPlayer?.numberOfLoops = -1
            alertPlayer?.volume = 1.0
            alertPlayer?.play()
        } catch {
            print("❌ Failed to play alert sound:", error)
        }
    }
    
    private func playAlertOnce() {
        stopAlertSound()

        var url: URL?

        if launchedFromStudy {
            if studyAlertSoundId == StudyAlertStorage.customSoundId {
                url = StudyAlertStorage.customSoundURL
            } else {
                let file = studyAlertSounds
                    .first(where: { $0.id == studyAlertSoundId })?
                    .fileName ?? "study_bell"

                url = Bundle.main.url(forResource: file, withExtension: "wav")
            }
        } else {
            url = Bundle.main.url(forResource: "alarm", withExtension: "wav")
        }

        guard let soundURL = url else {
            print("❌ Alert sound not found for one-shot")
            return
        }

        do {
            alertPlayer = try AVAudioPlayer(contentsOf: soundURL)
            alertPlayer?.numberOfLoops = 0    
            alertPlayer?.volume = 1.0
            alertPlayer?.play()
        } catch {
            print("❌ Failed to play one-shot alert sound:", error)
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
    
    private var canSwipeBack: Bool {
        !detector.isRunning &&
        !showingAlert &&
        !showAnalytics &&
        !isRestarting &&
        !isBreakActive 
    }
    
    private func pauseDetection() {
        isPaused = true
        detector.pauseProcessing()
        pomodoroTimer.stop()
    }

    private func resumeDetection() {
        isPaused = false

        detector.resumeProcessing()

        if detector.session == nil || !(detector.session?.isRunning ?? false) {
            startDetectorSafe()
        }

        if pomodoroDuration != nil && pomodoroTimer.remainingSeconds > 0 {
            pomodoroTimer.start(seconds: pomodoroTimer.remainingSeconds)
        }
    }
}
