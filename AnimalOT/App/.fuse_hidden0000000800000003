import Foundation
import SwiftUI

// MARK: - Device provisioning (the hard kid/parent split)
//
// Device type is identity, set ONCE at setup and stored LOCALLY on this physical
// device (UserDefaults — never synced). The synced store also holds an AppDevice
// registry row, but the *surface this build renders* is decided here, locally.
//
// Why local: the kid device's safety comes from ABSENCE of the parent surface.
// A synced flag could in principle arrive late or flip; the local value cannot.

@Observable
final class Provisioning {

    private let defaults = UserDefaults.standard
    private let typeKey = "device.type"
    private let deviceIdKey = "device.id"

    var deviceType: DeviceType? {
        didSet {
            if let t = deviceType {
                defaults.set(t.rawValue, forKey: typeKey)
            } else {
                defaults.removeObject(forKey: typeKey)
            }
        }
    }

    /// Stable per-install device id, generated once.
    let deviceId: UUID

    init() {
        if let raw = defaults.string(forKey: typeKey) {
            self.deviceType = DeviceType(rawValue: raw)
        } else {
            self.deviceType = nil
        }
        if let idStr = defaults.string(forKey: deviceIdKey), let id = UUID(uuidString: idStr) {
            self.deviceId = id
        } else {
            let id = UUID()
            defaults.set(id.uuidString, forKey: deviceIdKey)
            self.deviceId = id
        }
    }

    var isProvisioned: Bool { deviceType != nil }

    func provision(as type: DeviceType) {
        deviceType = type
    }

    /// Debug-only reset so you can re-provision a simulator without reinstalling.
    func resetForDebug() {
        deviceType = nil
    }
}
