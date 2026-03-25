import Foundation
import Observation

// Data describing the new bookmark being added (not yet persisted)
struct IncomingBookmark {
    let videoID: String
    let title: String
    let thumbnailURL: String
    let timestamp: Int
    let note: String
    let needsEnrichment: Bool
    let platform: String
    let folder: Folder?
}

// Holds both sides of a duplicate conflict
struct DuplicateConflict {
    let incoming: IncomingBookmark
    let existing: VideoRecord
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

    /// User chose "Cover existing record" — update timestamp + note
    func resolveCover() throws {
        guard let conflict = pendingConflict else { return }
        try repository.coverRecord(
            conflict.existing,
            timestamp: conflict.incoming.timestamp,
            note: conflict.incoming.note
        )
        pendingConflict = nil
    }

    /// User chose "Add New record" — create a separate record
    func resolveAddNew() throws {
        guard let conflict = pendingConflict else { return }
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
    }

    /// User dismissed without choosing — discard incoming
    func dismiss() {
        pendingConflict = nil
    }
}
