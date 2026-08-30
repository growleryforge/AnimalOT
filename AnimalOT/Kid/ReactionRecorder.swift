import Foundation
import ReplayKit

// MARK: - Silent reaction capture (kid iPad)
//
// Captures the kid screen INCLUDING his overlaid face — so the on-screen prompt
// and his attempt are stored together (screen + face), self-documenting. This is
// the unguarded signal an outside evaluator can never get.
//
// Privacy guardrails are non-negotiable:
//  • Off until a parent turns it on (CaptureConsent), revocable, per-session.
//  • Stays in the family iCloud only — no third party, no analytics SDK.
//  • The child sees NOTHING of it: no "how you did", no test framing. (iOS shows
//    its own status indicator while recording; that is the OS, not our UI.)

@MainActor
final class ReactionRecorder {

    private let recorder = RPScreenRecorder.shared()
    private(set) var isRecording = false

    /// Start silent capture. Microphone stays OFF by default (video of his face is
    /// the signal; audio is opt-in elsewhere).
    func start() async {
        guard CaptureConsent.isEnabled else { return }
        guard recorder.isAvailable, !recorder.isRecording else { return }
        recorder.isMicrophoneEnabled = false
        recorder.isCameraEnabled = false   // the front cam is already in the ARSCNView
        do {
            try await recorder.startRecording()
            isRecording = true
        } catch {
            // Never surface to the child. Capture simply doesn't happen this session.
            isRecording = false
        }
    }

    /// Stop and write the clip to family media. Returns the relative URI + duration
    /// so the caller can attach a MediaAsset to the GameSession.
    func stop() async -> (relativeURI: String, capturedAt: Date)? {
        guard isRecording, recorder.isRecording else { return nil }
        let (relative, url) = MediaStore.newVideoURL()
        do {
            try await recorder.stopRecording(withOutput: url)
            isRecording = false
            return (relative, Date())
        } catch {
            isRecording = false
            return nil
        }
    }

    func discard() async {
        guard recorder.isRecording else { return }
        _ = try? await recorder.stopRecording()
        isRecording = false
    }
}

// MARK: - Consent (explicit, revocable)

/// Camera/reaction capture is OFF until a parent turns it on. Stored locally on
/// the kid device (a parent flips it during setup or from the parent app via
/// sync in 1.x). Defaults to OFF — dignity by design.
enum CaptureConsent {
    private static let key = "capture.consent.enabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
