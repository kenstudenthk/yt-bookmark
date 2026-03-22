import Foundation

/// Written by ShareExtension, read and deleted by the main app on scenePhase == .active.
/// Stored as JSON in App Group UserDefaults under key "pendingRecord".
/// Only one pending record can exist at a time (last-write-wins with warning).
struct PendingRecord: Codable {
    let videoID: String
    let rawURL: String
    let timestamp: Int
    let savedAt: Date
    let note: String

    // MARK: - App Group

    static let userDefaultsKey = "pendingRecord"
    static let appGroupID = "group.com.myapp.ytbookmark"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Returns true if a pending record already exists in App Group UserDefaults.
    static func exists() -> Bool {
        sharedDefaults?.string(forKey: userDefaultsKey) != nil
    }

    /// Reads and decodes the pending record from App Group UserDefaults.
    /// Returns nil if absent or malformed.
    static func read() -> PendingRecord? {
        guard
            let json = sharedDefaults?.string(forKey: userDefaultsKey),
            let data = json.data(using: .utf8)
        else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PendingRecord.self, from: data)
    }

    /// Encodes and writes this record to App Group UserDefaults.
    /// Throws if encoding fails or the App Group suite is unavailable.
    func write() throws {
        guard let defaults = PendingRecord.sharedDefaults else {
            throw PendingRecordError.appGroupUnavailable
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw PendingRecordError.encodingFailed
        }
        defaults.set(json, forKey: PendingRecord.userDefaultsKey)
    }

    /// Deletes the pending record from App Group UserDefaults.
    static func delete() {
        sharedDefaults?.removeObject(forKey: userDefaultsKey)
    }
}

enum PendingRecordError: LocalizedError {
    case appGroupUnavailable
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable: "App Group UserDefaults unavailable."
        case .encodingFailed:      "Failed to encode bookmark data."
        }
    }
}
