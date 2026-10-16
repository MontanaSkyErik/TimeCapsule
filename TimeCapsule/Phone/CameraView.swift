@preconcurrency import AVFoundation
import SwiftUI
import UIKit

/// The rear camera. Only previews for now; recording comes later.
/// The session runs on its own queue so starting the camera never blocks the screen.
final class Camera: @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.session")
    private var configured = false

    func start() {
        print("[TimeCapsule] camera start, authorization:", AVCaptureDevice.authorizationStatus(for: .video).rawValue)
        AVCaptureDevice.requestAccess(for: .video) { [self] granted in
            print("[TimeCapsule] camera access granted:", granted)
            guard granted else { return }
            queue.async { [self] in
                configureIfNeeded()
                if !session.isRunning { session.startRunning() }
                print("[TimeCapsule] camera running:", session.isRunning, "inputs:", session.inputs.count)
            }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        NotificationCenter.default.addObserver(forName: AVCaptureSession.runtimeErrorNotification,
                                               object: session, queue: nil) { note in
            print("[TimeCapsule] camera error:", note.userInfo ?? [:])
        }
        NotificationCenter.default.addObserver(forName: AVCaptureSession.wasInterruptedNotification,
                                               object: session, queue: nil) { note in
            print("[TimeCapsule] camera interrupted:", note.userInfo ?? [:])
        }
        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1920x1080) { session.sessionPreset = .hd1920x1080 }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
    }
}

struct CameraView: UIViewRepresentable {
    let camera: Camera
    /// Fill the view (cropping), or show the whole upright frame.
    var fill = true

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.videoGravity = fill ? .resizeAspectFill : .resizeAspect
        view.previewLayer.session = camera.session
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        /// Keep the picture upright (portrait) once the camera is connected.
        override func layoutSubviews() {
            super.layoutSubviews()
            if let connection = previewLayer.connection, connection.videoRotationAngle != 90,
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }
}
