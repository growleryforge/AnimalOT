import Foundation

// MARK: - Local media storage
//
// Media is stored LOCALLY in the app container and synced via the family's own
// iCloud (CloudKit). A minor's photos/videos never go to a third party. URIs on
// MediaAsset are stored relative to this directory so they survive container
// path changes.

enum MediaStore {

    static var mediaDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("FamilyMedia", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(forRelative relative: String) -> URL {
        mediaDirectory.appendingPathComponent(relative)
    }

    static func newVideoURL() -> (relative: String, url: URL) {
        let name = "reaction-\(UUID().uuidString).mp4"
        return (name, mediaDirectory.appendingPathComponent(name))
    }

    static func delete(relative: String) {
        try? FileManager.default.removeItem(at: url(forRelative: relative))
    }
}
