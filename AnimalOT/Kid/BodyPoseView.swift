import SwiftUI
import AVFoundation
import Vision

// MARK: - Full-body "become the animal" mirror
//
// Front-camera live preview (iPad propped on the floor or held facing him) with
// Vision human-body-pose tracking. It reports his joints (normalized, mirrored to
// read like a mirror) so the move screen can pin animal features to his body, and
// an "effort" signal (how much he's moving) that fills the strength meter — so the
// exercise itself drives progress, no button needed.
//
// Note: body-pose accuracy and feature placement want a little on-device tuning;
// the mapping constants below are the knobs.

struct BodyPoseView: UIViewControllerRepresentable {
    /// Latest joints in normalized top-left view space (x mirrored). Keys are the
    /// Vision joint names (e.g. "nose", "left_ear", "root").
    var onPose: ([String: CGPoint]) -> Void = { _ in }
    /// 0...1 movement magnitude this frame (includes a small baseline while a body
    /// is present, so held poses still fill the meter slowly).
    var onEffort: (Double) -> Void = { _ in }

    func makeUIViewController(context: Context) -> BodyPoseController {
        let vc = BodyPoseController()
        vc.onPose = onPose
        vc.onEffort = onEffort
        return vc
    }

    func updateUIViewController(_ vc: BodyPoseController, context: Context) {}

    static func dismantleUIViewController(_ vc: BodyPoseController, coordinator: ()) {
        vc.stop()
    }
}

final class BodyPoseController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var onPose: ([String: CGPoint]) -> Void = { _ in }
    var onEffort: (Double) -> Void = { _ in }

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "body.pose.queue")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let poseRequest = VNDetectHumanBodyPoseRequest()

    private var lastPoints: [String: CGPoint] = [:]

    // (Vision joint, our stable key). We control the keys so the overlay is not
    // coupled to Vision's internal raw-string format.
    private let jointMap: [(VNHumanBodyPoseObservation.JointName, String)] = [
        (.nose, "nose"), (.leftEye, "leftEye"), (.rightEye, "rightEye"),
        (.leftEar, "leftEar"), (.rightEar, "rightEar"), (.neck, "neck"),
        (.leftShoulder, "leftShoulder"), (.rightShoulder, "rightShoulder"),
        (.leftElbow, "leftElbow"), (.rightElbow, "rightElbow"),
        (.leftWrist, "leftWrist"), (.rightWrist, "rightWrist"),
        (.root, "root"), (.leftHip, "leftHip"), (.rightHip, "rightHip"),
        (.leftKnee, "leftKnee"), (.rightKnee, "rightKnee"),
        (.leftAnkle, "leftAnkle"), (.rightAnkle, "rightAnkle")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        start()
    }

    private func configureSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else { return }
            self?.queue.async { self?.buildSession() }
        }
    }

    private func buildSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration(); return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let layer = AVCaptureVideoPreviewLayer(session: self.session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = self.view.bounds
            if let conn = layer.connection, conn.isVideoMirroringSupported {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = true   // read like a mirror
            }
            self.view.layer.insertSublayer(layer, at: 0)
            self.previewLayer = layer
        }
    }

    func start() {
        queue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: Frame → pose

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([poseRequest])
        guard let obs = poseRequest.results?.first else {
            DispatchQueue.main.async { [weak self] in self?.onEffort(0) }
            return
        }

        var points: [String: CGPoint] = [:]
        for (joint, key) in jointMap {
            if let p = try? obs.recognizedPoint(joint), p.confidence > 0.2 {
                // Vision: normalized, origin bottom-left. Mirror x, flip y → top-left.
                points[key] = CGPoint(x: 1 - p.location.x, y: 1 - p.location.y)
            }
        }

        var motion = 0.0
        var counted = 0
        for (k, p) in points {
            if let last = lastPoints[k] {
                motion += hypot(p.x - last.x, p.y - last.y)
                counted += 1
            }
        }
        let avg = counted > 0 ? motion / Double(counted) : 0
        let present = points.count >= 6
        let effort = min(1.0, avg * 6.0 + (present ? 0.02 : 0))   // base trickle for holds
        lastPoints = points

        DispatchQueue.main.async { [weak self] in
            self?.onPose(points)
            self?.onEffort(effort)
        }
    }
}
