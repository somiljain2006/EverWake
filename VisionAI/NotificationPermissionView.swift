import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    
    @State private var showModeSelection = false
    @State private var isRequesting = false
    
    @AppStorage("isSetupComplete") private var isSetupComplete = false

    private let bgColor = Color(hex: "#2D3135")
    private let accentColor = Color(hex: "#C37CAB")
    private let buttonColor = Color(hex: "#49494A")

    var body: some View {
        if showModeSelection {
            ModeSelectionView()
                .transition(.opacity)
        } else {
            notificationView
                .transition(.opacity)
        }
    }

    private var notificationView: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer(minLength: 50)

                Image("notification_permission")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .shadow(radius: 12)

                Text("Notification\nAccess Required")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Enable notifications to get instant alerts\nand updates.")
                    .font(.system(size: 17))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 3) {
                    Label("Drowsiness warnings", systemImage: "checkmark")
                    Label("Pomodoro reminders", systemImage: "checkmark")
                    Label("No promotional spam", systemImage: "checkmark")
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.leading, 32)
                .padding(.top, -4)

                Spacer()

                Button {
                    isRequesting = true
                    requestNotificationPermission()
                } label: {
                    Text("Allow")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(buttonColor)
                        .cornerRadius(14)
                }
                .disabled(isRequesting)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        
        .onAppear {
            UNUserNotificationCenter.current()
                .getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        if settings.authorizationStatus == .authorized ||
                           settings.authorizationStatus == .provisional {
                            finishSetup()
                        }
                    }
                }
        }
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    withAnimation {
                        showModeSelection = true
                    }
                } else {
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                isRequesting = false
                                finishSetup()
                                withAnimation {
                                    showModeSelection = true
                                }
                            } else {
                                isRequesting = false
                                openAppSettings()
                            }
                        }
                    }
                }
            }
        }
    }
    private func finishSetup() {
            isSetupComplete = true
            withAnimation {
                showModeSelection = true
            }
    }
}

private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}
