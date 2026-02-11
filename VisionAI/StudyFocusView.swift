import SwiftUI
import AVFoundation

struct StudyFocusView: View {
    @Environment(\.dismiss) private var dismiss

    private let bgColor = Color(hex: "#2D3135")
    private let accent = Color(hex: "#8B8CFB")
    private let buttonColor = Color(hex: "#6C63FF")

    @State private var selectedMinutes: Int = 25
    @State private var customMinutes: Int = 25
    @State private var selectedSeconds: Int = 0
    @State private var customSeconds: Int = 0
    @State private var isPomodoroEnabled: Bool = false
    @State private var showDetection = false
    @State private var avatarImage: UIImage? = nil
    @State private var isViewReady = false

    private let pickerRowHeight: CGFloat = 80
    private let pickerWidth: CGFloat = 104

    private let backButtonOffset: CGFloat = 52

    @AppStorage("profileImageData") private var profileImageData: Data?

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    if isViewReady {
                        if isPomodoroEnabled {
                            pomodoroContent
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        } else {
                            DriverStartUI(onStart: { print("Driver detection started") })
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: isPomodoroEnabled)

                Spacer()

                VStack(spacing: 18) {
                    HStack {
                        Text(isPomodoroEnabled ? "Pomodoro Timer" : "Driver Detection")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Toggle("", isOn: $isPomodoroEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: buttonColor))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(width: 320)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(16)

                    Button {
                        showDetection = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                            Text("Start detection")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(buttonColor)
                        .cornerRadius(16)
                        .shadow(radius: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
                .opacity(isViewReady ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: isViewReady)
            }

            topBar
                .ignoresSafeArea(edges: .top)
                .zIndex(999)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { EmptyView() }
        }
        .onAppear {
            selectedMinutes = min(max(selectedMinutes, 25), 60)
            customMinutes = selectedMinutes
            
            if avatarImage == nil, let data = profileImageData {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let decoded = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.avatarImage = decoded
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isViewReady = true
            }
        }
        .navigationDestination(isPresented: $showDetection) {
            let totalSeconds = (selectedMinutes * 60) + selectedSeconds
            DriverDetectionView(
                autoStart: true,
                pomodoroDuration: isPomodoroEnabled ? totalSeconds : nil,
                launchedFromStudy: true
            )
        }
    }

    private var topBar: some View {
        GeometryReader { geo in
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .padding(.leading, 16)

                Spacer()

                Button {
                    // profile tapped
                } label: {
                    Group {
                        if let ui = avatarImage {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .padding(.trailing, 16)
            }
            .padding(.top, geo.safeAreaInsets.top + backButtonOffset)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var pomodoroContent: some View {
        VStack {
            Spacer(minLength: 60)

            Text(breakText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(accent)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Capsule().fill(accent.opacity(0.15)))
                .padding(.bottom, 15)

            ZStack {
                Circle()
                    .stroke(accent.opacity(0.35), lineWidth: 10)
                    .frame(width: 220, height: 220)

                HStack(spacing: -14) {
                    MinuteWheelPicker(range: 25...60, selection: $customMinutes, rowHeight: pickerRowHeight)
                        .frame(width: pickerWidth, height: 180)
                        .clipped()
                        .onChange(of: customMinutes) { _, newValue in
                            let clamped = min(max(newValue, 25), 60)
                            selectedMinutes = clamped
                            customMinutes = clamped
                        }

                    Text(":")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .baselineOffset(6)

                    MinuteWheelPicker(range: 0...59, selection: $customSeconds, rowHeight: pickerRowHeight)
                        .frame(width: pickerWidth, height: 180)
                        .clipped()
                }
                .frame(width: 280, height: 180)
                .mask(Circle().frame(width: 250, height: 250))
            }

            Text("“The successful warrior is the average person, with laser-like focus.”")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 18)

            HStack(spacing: 14) {
                durationChip(25)
                durationChip(45)
                durationChip(60)
            }
            .padding(.top, 18)

            Spacer(minLength: 40)
        }
    }

    private var breakText: String {
        let breakMin = breakMinutes(for: selectedMinutes)
        return "\(breakMin) min break"
    }

    private func durationChip(_ minutes: Int) -> some View {
        Button {
            selectedMinutes = minutes
            selectedSeconds = 0
            customMinutes = minutes
            customSeconds = 0
        } label: {
            Text("\(minutes)m")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(selectedMinutes == minutes ? accent : .white.opacity(0.6))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selectedMinutes == minutes ? accent.opacity(0.15) : Color.white.opacity(0.08))
                )
        }
    }

    private func breakMinutes(for focusMinutes: Int) -> Int {
        let raw = 0.2857 * Double(focusMinutes) - 2.14
        return max(5, Int(floor(raw)))
    }
}
