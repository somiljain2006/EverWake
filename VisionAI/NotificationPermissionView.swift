import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {

    private let bgColor = Color(hex: "#2D3135")
    private let accentColor = Color(hex: "#C37CAB")
    private let buttonColor = Color(hex: "#49494A")

    var body: some View {
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

                Text("Enable notifications to get instant alert\nand updates.")
                    .font(.system(size: 17))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Drowsiness warnings", systemImage: "checkmark")
                    Label("Pomodoro reminders", systemImage: "checkmark")
                    Label("No promotional spam", systemImage: "checkmark")
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.top, 8)

                Spacer()

                Button {
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
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        print("Notification permission granted")
                    } else {
                        openAppSettings()
                    }
                }
            }
    }
}

private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}
