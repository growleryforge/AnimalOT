import Foundation

// MARK: - Domain enums
//
// These are stored on the models as raw `String` values so the schema stays
// CloudKit-friendly (CloudKit-backed SwiftData wants simple, optional/defaulted
// attributes). Each model exposes a typed accessor that wraps the raw string.

/// The sensory system a game surfaces.
enum SensorySystem: String, CaseIterable, Codable, Identifiable {
    case vestibular
    case proprioceptive
    case tactile
    case auditory
    case praxis

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vestibular:     return "Vestibular"
        case .proprioceptive: return "Proprioceptive"
        case .tactile:        return "Tactile"
        case .auditory:       return "Auditory"
        case .praxis:         return "Praxis"
        }
    }

    var blurb: String {
        switch self {
        case .vestibular:     return "Movement & balance — how his body reads motion and gravity."
        case .proprioceptive: return "Heavy work & deep pressure — the regulating ‘gold pattern.’"
        case .tactile:        return "Touch — which textures he seeks vs. recoils from."
        case .auditory:       return "Sound — seeking vs. defending, and who controls the trigger."
        case .praxis:         return "Motor planning — mapping a watched movement onto his own body."
        }
    }
}

/// How a game is captured.
enum CaptureMode: String, CaseIterable, Codable, Identifiable {
    case guided
    case quick
    case either

    var id: String { rawValue }

    var label: String {
        switch self {
        case .guided: return "Guided"
        case .quick:  return "Quick-capture"
        case .either: return "Either"
        }
    }
}

/// Who holds the phone for a game (matches the skill being surfaced).
enum PhoneHolder: String, CaseIterable, Codable, Identifiable {
    case parentRun = "parent_run"
    case kidFacing = "kid_facing"
    case parentRunChildSees = "parent_run_child_sees"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .parentRun:          return "Parent-run"
        case .kidFacing:          return "Kid-facing"
        case .parentRunChildSees: return "Parent-run, child sees/hears"
        }
    }
}

/// Whether control of the sensory input sat with the child or was imposed.
/// Control is a first-class variable — the control-flip insight depends on it.
enum ControlState: String, CaseIterable, Codable, Identifiable {
    case controlMet = "control_met"        // self-initiated / he ran it
    case controlAbsent = "control_absent"  // imposed
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .controlMet:    return "He was in control"
        case .controlAbsent: return "It was imposed"
        case .unknown:       return "Not noted"
        }
    }
}

/// Device identity is set at provisioning and determines the entire surface.
/// This is the hard kid/parent split — not a toggle.
enum DeviceType: String, CaseIterable, Codable, Identifiable {
    case kid     // iPad: games only
    case parent  // phone: full app

    var id: String { rawValue }
}

enum UserRole: String, CaseIterable, Codable {
    case parent
    case child
    case clinicianView = "clinician_view"
}

enum MediaType: String, Codable {
    case photo
    case video
}

/// Where a media asset came from. Kid-device capture is always front-cam.
enum MediaSource: String, Codable {
    case kidFrontCam = "kid_front_cam"
    case parentPhone = "parent_phone"
}

/// In-app behavior signal kinds. These are logged silently while the child plays.
enum BehaviorKind: String, Codable {
    case choice        // which game he chose
    case repeatAction = "repeat"   // repeated a game / action
    case avoid         // avoided / bailed
    case complete      // finished a clear task
    case controlSet = "control_set" // set an in-game control (e.g. volume)
    case duration      // time-on-game
}
