import SwiftUI
import AVFoundation
import Vision
import Combine

final class EyeDetector: NSObject, ObservableObject {
    @Published var isRunning: Bool = false
    @Published var eyesOpen: Bool = true
    @Published var closedDuration: TimeInterval = 0
    @Published var isStarting: Bool = false

    var onEyesClosedLong: (() -> Void)?
    private let closedThreshold: TimeInterval = 5.0
    private var lastFaceSeen: Date?

    var session: AVCaptureSession?
    private let videoQueue = DispatchQueue(label: "vision.video.queue")
    private var lastClosedStart: Date?
    private var lastFrameTime: Date?

    private lazy var faceRequest: VNDetectFaceLandmarksRequest = {
        VNDetectFaceLandmarksRequest { [weak self] request, _ in
            guard let self = self else { return }

            if let face = (request.results as? [VNFaceObservation])?.first {
                self.lastFaceSeen = Date()
                self.processFaceObservation(face)
            } else {
                self.handleNoFace()
            }
        }
    }()
    
    func start() {
        guard !isRunning else { return }
        isStarting = true
        isRunning = true
        checkPermissionAndStart()
    }

    func stop() {
        lastClosedStart = nil
        closedDuration = 0
        eyesOpen = true
        isStarting = false
        isRunning = false
        if let session = session, session.isRunning {
            session.stopRunning()
        }
        session = nil
    }

    private func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSessionAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupSessionAndStart() }
                }
            }
        default:
            break
        }
    }

    private func setupSessionAndStart() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("❌ cannot create front camera input")
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        output.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(output) else {
            print("❌ can't add video output")
            return
        }
        session.addOutput(output)

        if let conn = output.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if conn.isVideoRotationAngleSupported(0) {
                    conn.videoRotationAngle = 0
                }
            } else {
                if conn.isVideoOrientationSupported {
                    conn.videoOrientation = .portrait
                }
            }
        }

        session.commitConfiguration()
        self.session = session

        videoQueue.async { [weak self] in
            self?.session?.startRunning()
            DispatchQueue.main.async {
                self?.isStarting = false
            }
        }
    }

    private func handleNoFace() {
        DispatchQueue.main.async {
            self.eyesOpen = false
            
            if self.lastClosedStart == nil {
                self.lastClosedStart = Date()
            } else {
                self.closedDuration = Date().timeIntervalSince(self.lastClosedStart!)
                
                if self.closedDuration >= self.closedThreshold {
                    self.onEyesClosedLong?()
                }
            }
        }
    }
}

extension EyeDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        do {
            try handler.perform([self.faceRequest])
        } catch {
            // ignore errors during detection
        }
    }

    private func processFaceObservation(_ face: VNFaceObservation) {
        guard let landmarks = face.landmarks else {
            handleNoFace()
            return
        }

        func openness(for eye: VNFaceLandmarkRegion2D?, boundingBox: CGRect) -> CGFloat? {
            guard let eye = eye, eye.pointCount > 5 else { return nil }
            let pts = (0..<eye.pointCount).map { i in
                eye.normalizedPoints[i]
            }

            let ys = pts.map { $0.y }
            let xs = pts.map { $0.x }
            guard let minY = ys.min(), let maxY = ys.max(), let minX = xs.min(), let maxX = xs.max() else { return nil }

            let vertical = maxY - minY
            let horizontal = maxX - minX
            guard horizontal > 0.0001 else { return nil }
            return vertical / horizontal
        }

        let leftOp = openness(for: landmarks.leftEye, boundingBox: face.boundingBox)
        let rightOp = openness(for: landmarks.rightEye, boundingBox: face.boundingBox)

        var avgOp: CGFloat? = nil
        if let l = leftOp, let r = rightOp {
            avgOp = (l + r) / 2.0
        } else {
            avgOp = leftOp ?? rightOp
        }

        DispatchQueue.main.async {
            guard let avg = avgOp else {
                self.eyesOpen = false
                if self.lastClosedStart == nil {
                    self.lastClosedStart = Date()
                } else {
                    self.closedDuration = Date().timeIntervalSince(self.lastClosedStart!)
                    if self.closedDuration >= self.closedThreshold {
                        self.onEyesClosedLong?()
                    }
                }
                return
            }

            let threshold: CGFloat = 0.18
            if avg > threshold {
                self.eyesOpen = true
                self.lastClosedStart = nil
                self.closedDuration = 0
            } else {
                if self.lastClosedStart == nil {
                    self.lastClosedStart = Date()
                }
                self.closedDuration = Date().timeIntervalSince(self.lastClosedStart!)
                self.eyesOpen = false
                if self.closedDuration >= self.closedThreshold {
                    self.onEyesClosedLong?()
                }
            }
        }
    }
}
