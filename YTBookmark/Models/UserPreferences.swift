import Foundation

enum UserPreferences {
    static let defaultFolderIDKey = "defaultFolderID"

    static func defaultFolderID(in store: UserDefaults = .standard) -> UUID? {
        store.string(forKey: defaultFolderIDKey).flatMap(UUID.init)
    }

    static func setDefaultFolderID(_ id: UUID, in store: UserDefaults = .standard) {
        store.set(id.uuidString, forKey: defaultFolderIDKey)
    }

    static func clearDefaultFolderID(in store: UserDefaults = .standard) {
        store.removeObject(forKey: defaultFolderIDKey)
    }
}
