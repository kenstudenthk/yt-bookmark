import Foundation
import Observation

// Data describing the new bookmark being added (not yet persisted)
struct IncomingBookmark: Equatable {
    let videoID: String
    let title: String
    let thumbnailURL: String
    let timestamp: Int
    let note: String
    let needsEnrichment: Bool
    let platform: String
    let folder: Folder?

    static func == (lhs: IncomingBookmark, rhs: IncomingBookmark) -> Bool {
        lhs.videoID == rhs.videoID &&
        lhs.timestamp == rhs.timestamp &&
        lhs.note == rhs.note
    }
}

// Holds both sides of a duplicate conflict
struct DuplicateConflict: Equatable {
    let incoming: IncomingBookmark
    let existing: VideoRecord

    static func == (lhs: DuplicateConflict, rhs: DuplicateConflict) -> Bool {
        lhs.incoming == rhs.incoming &&
        lhs.existing.id == rhs.existing.id
    }
}

@Observable
final class ConflictStore {
    var pendingConflict: DuplicateConflict? = nil
    var errorMessage: String? = nil

    private let repository: BookmarkRepository

    init(repository: BookmarkRepository) {
        self.repository = repository
    }

    /// Called when a duplicate is detected — posts conflict for UI to handle
    func raise(_ conflict: DuplicateConflict) {
        pendingConflict = conflict
    }

    /// User chose "Cover existing record" — update timestamp + note.
    /// Pass a `SavingMethod` to `rememberAs` to persist the per-video preference.
    func resolveCover(rememberAs method: SavingMethod? = nil) throws {
        guard let conflict = pendingConflict else { return }
        if let method = method {
            try repository.updateSavingMethod(on: conflict.existing, method: method)
        }
        try repository.coverRecord(
            conflict.existing,
            timestamp: conflict.incoming.timestamp,
            note: conflict.incoming.note
        )
        pendingConflict = nil
        refreshWidgetData()
    }

    /// User chose "Add New record" — create a separate record.
    /// Pass a `SavingMethod` to `rememberAs` to persist the per-video preference.
    func resolveAddNew(rememberAs method: SavingMethod? = nil) throws {
        guard let conflict = pendingConflict else { return }
        if let method = method {
            try repository.updateSavingMethod(on: conflict.existing, method: method)
        }
        let b = conflict.incoming
        _ = try repository.createRecord(
            videoID: b.videoID,
            title: b.title,
            thumbnailURL: b.thumbnailURL,
            timestamp: b.timestamp,
            note: b.note,
            needsEnrichment: b.needsEnrichment,
            folder: b.folder,
            platform: b.platform
        )
        pendingConflict = nil
        refreshWidgetData()
    }

    /// User dismissed without choosing — discard incoming
    func dismiss() {
        pendingConflict = nil
    }

    // MARK: - Private

    private func refreshWidgetData() {
        let recent = (try? repository.fetchRecentRecords(limit: 5)) ?? []
        WidgetDataService.update(with: recent)
    }
}
