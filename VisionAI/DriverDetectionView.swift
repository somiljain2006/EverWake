import SwiftUI
import AVFoundation

struct DriverDetectionView: View {
    
    @StateObject private var detector = EyeDetector()
    
    private let bgColor = Color(hex: "#2D3135")
    private let buttonColor = Color(hex: "#49494A")
    
    var body: some View {
        ZStack {
            if detector.isRunning {
                CameraPreview(session: detector.session)
                    .ignoresSafeArea()
            } else {
                bgColor.ignoresSafeArea()
            }
            
            if detector.isRunning && detector.closedDuration > 5.0 {
                Color.red.opacity(0.5)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: detector.closedDuration > 5.0)
            }
            
            VStack {
                HStack {
                    if detector.isRunning {
                        Image("eyes-wide")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .padding(.leading, 18)
                            .shadow(radius: 2)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                }
                .padding(.top, -10)
                .offset(y: -5)
                
                Spacer()
                
                if !detector.isRunning {
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
                }
                
                if detector.isRunning {
                    Text(detector.closedDuration > 5.0 ? "DROWSINESS DETECTED!" : "Eyes Open")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(detector.closedDuration > 5.0 ? Color.red : Color(hex: "#459E48"))
                        .padding(.top, 8)
                        .shadow(color: .black.opacity(0.8), radius: 2)
                } else {
                    Text("Ready to Start")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                Button(action: toggleDetection) {
                    Text(detector.isRunning ? "Stop Detection" : "Start Detection")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(detector.isRunning ? Color.red.opacity(0.9) : buttonColor)
                        .cornerRadius(14)
                        .shadow(radius: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(detector.$closedDuration) { duration in
            if duration > 5.00 {
                print("🚨 Eyes closed for \(duration)s — TRIGGER ALARM HERE")
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
    
    struct CameraPreview: UIViewRepresentable {
        let session: AVCaptureSession?

        func makeUIView(context: Context) -> VideoPreviewView {
            let view = VideoPreviewView()
            view.backgroundColor = .black
            view.videoPreviewLayer.session = session
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            view.videoPreviewLayer.connection?.videoRotationAngle = 90
            return view
        }

        func updateUIView(_ uiView: VideoPreviewView, context: Context) {
            if uiView.videoPreviewLayer.session != session {
                uiView.videoPreviewLayer.session = session
            }
            if let connection = uiView.videoPreviewLayer.connection {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                } else {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                }
            }
        }
    }

    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
