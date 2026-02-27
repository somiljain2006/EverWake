import SwiftUI
import AVFoundation

struct CameraPermissionView: View {
    
    @State private var showNotifications = false
    @State private var isRequesting = false

    private let bgColor = Color(hex: "#2D3135")
    private let headingColor = Color(hex: "#C37CAB")
    private let buttonColor = Color(hex: "#49494A")
    private let subtitleColor = Color(hex: "#C37CAB")

    var body: some View {
        if showNotifications {
            NotificationPermissionView()
                .transition(.opacity)
        } else {
            cameraView
                .transition(.opacity)
        }
    }

    private var cameraView: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer(minLength: 40)

                Image("camera_permission")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .offset(x: -12)
                    .shadow(radius: 12)

                Text("Camera Access\nRequired")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("EverWake uses your camera to detect eye\nclosure and body movements.")
                    .font(.system(size: 17))
                    .foregroundColor(headingColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("On-device processing", systemImage: "checkmark")
                        Label("Privacy-first design", systemImage: "checkmark")
                        Label("No photos or videos", systemImage: "checkmark")
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)

                Spacer()

                Button {
                    isRequesting = true
                    requestCameraPermission()
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
                .opacity(isRequesting ? 0.6 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        
        .onAppear {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                showNotifications = true
            }
        }
    }


    private func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        isRequesting = false
                        withAnimation {
                            showNotifications = true
                        }
                    } else {
                        isRequesting = false
                    }
                }
            }

        case .authorized:
            isRequesting = false
            withAnimation {
                showNotifications = true
            }

        case .denied, .restricted:
            isRequesting = false
            DispatchQueue.main.async {
                openAppSettings()
            }

        @unknown default:
            break
        }
    }
}

private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}

struct CameraPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPermissionView()
            .previewDevice("iPhone 14 Pro")
    }
}
