import SwiftUI
@preconcurrency import AVFoundation
@preconcurrency import Vision
import Combine
import CoreMedia
@preconcurrency import AVKit

@MainActor
final class EyeDetector: NSObject, ObservableObject {
    @Published var isRunning: Bool = false
    @Published var eyesOpen: Bool = true
    @Published var closedDuration: TimeInterval = 0
    @Published var isStarting: Bool = false
    @Published var totalTripDuration: TimeInterval = 0
    @Published var hasRenderedFirstFrame = false

    @Published private(set) var alertsCount: Int = 0
    @Published private(set) var lastSessionDuration: TimeInterval = 0
    @Published private(set) var lastSessionAlerts: Int = 0
    
    nonisolated(unsafe) private var didFlushAfterFailure = false

    nonisolated(unsafe) private var _hasEnqueuedFirstFrame = false
    nonisolated(unsafe) let activePipLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    var onEyesClosedLong: (() -> Void)?
    var pipController: AVPictureInPictureController?

    private let closedThreshold: TimeInterval = 2.5
    private var lastFaceSeen: Date?

    nonisolated(unsafe) var session: AVCaptureSession?
    private let videoQueue = DispatchQueue(label: "vision.video.queue")
    private var lastClosedStart: Date?
    private var lastFrameTime: Date?
    private var sessionStart: Date?
    private var alertedWhileClosed: Bool = false

    nonisolated(unsafe) private var faceRequest: VNDetectFaceLandmarksRequest?

    private func buildFaceRequest() {
        let request = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let self else { return }
            if let face = (req.results as? [VNFaceObservation])?.first {
                self.processFaceObservation(face)
            } else {
                self.handleNoFace()
            }
        }
        faceRequest = request
    }

    func start() {
        DispatchQueue.main.async {
            guard !self.isRunning else { return }
            self.isStarting = true
            self.isRunning = true
            self.alertsCount = 0
            self.sessionStart = Date()
        }

        checkPermissionAndStart()
    }

    func stop() {
        pipController?.stopPictureInPicture()
        let duration: TimeInterval = sessionStart.map { Date().timeIntervalSince($0) } ?? 0
        let sessionToStop = session
        session = nil

        videoQueue.async { [weak self] in
            sessionToStop?.stopRunning()
            self?.faceRequest = nil
            self?._hasEnqueuedFirstFrame = false
        }

        DispatchQueue.main.async {
            self.lastSessionDuration = duration
            self.totalTripDuration += duration
            self.lastSessionAlerts = self.alertsCount

            self.lastClosedStart = nil
            self.closedDuration = 0
            self.eyesOpen = true
            self.isStarting = false
            self.isRunning = false
            self.alertedWhileClosed = false
            self.sessionStart = nil
            self.hasRenderedFirstFrame = false
        }

        if let session = session, session.isRunning {
            session.stopRunning()
        }
        session = nil
    }
    
    func resetTrip() {
        totalTripDuration = 0
        lastSessionDuration = 0
    }

    func registerAlert() {
        alertsCount += 1
    }
    
    private func checkPermissionAndStart() {
        // Request Camera Permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] videoGranted in
            guard let self = self else { return }
            
            if videoGranted {
                // Request Microphone Permission
                AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                    DispatchQueue.main.async {
                        if audioGranted {
                            self.setupSessionAndStart()
                        } else {
                            print("⚠️ Audio permission denied. App will try to run, but PiP might freeze in background.")
                            // We can still try to start, but without audio it might freeze in background
                            self.setupSessionAndStart()
                        }
                    }
                }
            } else {
                print("❌ Camera permission denied.")
            }
        }
    }

    private func setupSessionAndStart() {
        // ✨ ADD THIS: Explicitly activate the background Audio Session first!
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .videoChat, options: [.mixWithOthers, .allowBluetoothHFP])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to activate audio session:", error)
        }

        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        session.automaticallyConfiguresApplicationAudioSession = false

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("❌ cannot create front camera input")
            return
        }
        session.addInput(input)
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(audioInput) {
            session.addInput(audioInput)
            let audioOutput = AVCaptureAudioDataOutput()
            if session.canAddOutput(audioOutput) {
                session.addOutput(audioOutput)
            }
        } else {
            print("⚠️ Could not add audio input. PiP might freeze in background.")
        }

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
                // ✨ FIX 2: Change 0 to 90. 0 means landscape, 90 means portrait!
                if conn.isVideoRotationAngleSupported(90) {
                    conn.videoRotationAngle = 90
                }
            } else {
                if conn.isVideoOrientationSupported {
                    conn.videoOrientation = .portrait
                }
            }
        }
        
        if #available(iOS 16.0, *) {
            if session.isMultitaskingCameraAccessSupported {
                session.isMultitaskingCameraAccessEnabled = true
            }
        }

        session.commitConfiguration()

        self.session = session
        buildFaceRequest()

        videoQueue.async { [weak self] in
            self?.session?.startRunning()
            DispatchQueue.main.async {
                self?.isStarting = false
            }
        }
    }

    nonisolated private func handleNoFace() {
        DispatchQueue.main.async {
            self.eyesOpen = false
            
            if self.lastClosedStart == nil {
                self.lastClosedStart = Date()
            } else {
                self.closedDuration = Date().timeIntervalSince(self.lastClosedStart!)
                
                if self.closedDuration >= self.closedThreshold && !self.alertedWhileClosed {
                    self.alertedWhileClosed = true
                    self.onEyesClosedLong?()
                }
            }
        }
    }
}

extension EyeDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if !_hasEnqueuedFirstFrame {
            _hasEnqueuedFirstFrame = true
            DispatchQueue.main.async { self.hasRenderedFirstFrame = true }
        }

        // Tag each frame to display immediately — no timebase scheduling needed
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) {
            let dict = unsafeBitCast(
                CFArrayGetValueAtIndex(attachments, 0),
                to: CFMutableDictionary.self
            )
            CFDictionarySetValue(
                dict,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }

        let status: AVQueuedSampleBufferRenderingStatus
                if #available(iOS 18.0, *) {
                    status = activePipLayer.sampleBufferRenderer.status
                } else {
                    status = activePipLayer.status
                }

                if status == .failed {
                    Task { @MainActor in self.flushPiPLayer() }
                    return
                }

        if #available(iOS 18.0, *) {
            activePipLayer.sampleBufferRenderer.enqueue(sampleBuffer)
        } else {
            activePipLayer.enqueue(sampleBuffer)
        }

        guard let faceRequest else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([faceRequest])
    }

    nonisolated private func processFaceObservation(_ face: VNFaceObservation) {
        guard let landmarks = face.landmarks else {
            handleNoFace()
            return
        }

        func openness(for eye: VNFaceLandmarkRegion2D?) -> CGFloat? {
            guard let eye = eye, eye.pointCount > 5 else { return nil }
            let pts = (0..<eye.pointCount).map { eye.normalizedPoints[$0] }
            let ys = pts.map { $0.y }
            let xs = pts.map { $0.x }
            guard let minY = ys.min(), let maxY = ys.max(),
                  let minX = xs.min(), let maxX = xs.max() else { return nil }
            let horizontal = maxX - minX
            guard horizontal > 0.0001 else { return nil }
            return (maxY - minY) / horizontal
        }

        let leftOp = openness(for: landmarks.leftEye)
        let rightOp = openness(for: landmarks.rightEye)
        let avgOp: CGFloat?
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
                    if self.closedDuration >= self.closedThreshold && !self.alertedWhileClosed {
                        self.alertedWhileClosed = true
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
                self.alertedWhileClosed = false 
            } else {
                if self.lastClosedStart == nil {
                    self.lastClosedStart = Date()
                }
                self.closedDuration = Date().timeIntervalSince(self.lastClosedStart!)
                self.eyesOpen = false
                if self.closedDuration >= self.closedThreshold && !self.alertedWhileClosed {
                    self.alertedWhileClosed = true
                    self.onEyesClosedLong?()
                }
            }
        }
    }
    
    func acknowledgeAlertAndReset() {
        alertedWhileClosed = true
        lastClosedStart = nil
        closedDuration = 0
    }
    
    nonisolated private func startCaptureSession(_ session: AVCaptureSession) {
            session.startRunning()
    }
    
    func flushPiPLayer() {
        if #available(iOS 18.0, *) {
            activePipLayer.sampleBufferRenderer.flush(removingDisplayedImage: true, completionHandler: nil)
        } else {
            activePipLayer.flushAndRemoveImage()
        }
    }
}
