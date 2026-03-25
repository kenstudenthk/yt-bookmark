import Foundation
import SwiftData

/// The only layer that reads or writes SwiftData.
/// ViewModels call this; never access ModelContext directly from a ViewModel or View.
final class BookmarkRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - VideoRecord: Create

    /// Creates and saves a new VideoRecord from ingested pending record data and API metadata.
    @discardableResult
    func createRecord(
        videoID: String,
        title: String,
        thumbnailURL: String,
        timestamp: Int,
        note: String = "",
        needsEnrichment: Bool = false,
        folder: Folder? = nil,
        platform: String = "youtube"
    ) throws -> VideoRecord {
        let record = VideoRecord(
            videoID: videoID,
            title: title,
            thumbnailURL: thumbnailURL,
            lastTimestamp: timestamp,
            note: note,
            needsEnrichment: needsEnrichment,
            platform: platform,
            folder: folder
        )
        context.insert(record)
        try context.save()
        return record
    }

    // MARK: - VideoRecord: Fetch

    /// All records sorted by savedAt descending (newest first).
    func fetchAllRecords() throws -> [VideoRecord] {
        let descriptor = FetchDescriptor<VideoRecord>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// The most recent N records (for widget data).
    func fetchRecentRecords(limit: Int) throws -> [VideoRecord] {
        var descriptor = FetchDescriptor<VideoRecord>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    /// Records where the YouTube API fetch failed and a retry is needed.
    func fetchRecordsNeedingEnrichment() throws -> [VideoRecord] {
        let descriptor = FetchDescriptor<VideoRecord>(
            predicate: #Predicate { $0.needsEnrichment == true }
        )
        return try context.fetch(descriptor)
    }

    // MARK: - VideoRecord: Update

    /// Updates the note on a record. Enforces 500-char max.
    func updateNote(on record: VideoRecord, note: String) throws {
        record.note = String(note.prefix(500))
        try context.save()
    }

    /// Moves a record to a folder (or nil for uncategorised).
    func moveRecord(_ record: VideoRecord, to folder: Folder?) throws {
        record.folder = folder
        try context.save()
    }

    /// Applies YouTube API metadata after a successful enrichment fetch.
    func applyEnrichment(to record: VideoRecord, title: String, thumbnailURL: String) throws {
        record.title = title
        record.thumbnailURL = thumbnailURL
        record.needsEnrichment = false
        try context.save()
    }

    // MARK: - VideoRecord: Delete

    func deleteRecord(_ record: VideoRecord) throws {
        context.delete(record)
        try context.save()
    }

    // MARK: - Folder: Create

    @discardableResult
    func createFolder(name: String, colorHex: String) throws -> Folder {
        let folder = Folder(name: String(name.prefix(30)), colorHex: colorHex)
        context.insert(folder)
        try context.save()
        return folder
    }

    // MARK: - Folder: Fetch

    /// All folders sorted by createdAt ascending (oldest first).
    func fetchAllFolders() throws -> [Folder] {
        let descriptor = FetchDescriptor<Folder>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Folder: Delete

    /// Deletes the folder. Records in this folder have their folder set to nil
    /// automatically via the .nullify delete rule on the relationship.
    func deleteFolder(_ folder: Folder) throws {
        context.delete(folder)
        try context.save()
    }

    // MARK: - VideoRecord: Duplicate Detection

    /// Finds the first VideoRecord matching the given videoID, or nil if none exists.
    func findFirstRecord(videoID: String) throws -> VideoRecord? {
        let predicate = #Predicate<VideoRecord> { $0.videoID == videoID }
        let descriptor = FetchDescriptor<VideoRecord>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    /// Overwrites the timestamp and note on an existing record (Cover conflict resolution).
    func coverRecord(_ record: VideoRecord, timestamp: Int, note: String) throws {
        record.lastTimestamp = timestamp
        record.note = note
        try context.save()
    }

    /// Finds a Folder by its UUID, or nil if not found.
    func fetchFolder(byID id: UUID) throws -> Folder? {
        let predicate = #Predicate<Folder> { $0.id == id }
        let descriptor = FetchDescriptor<Folder>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    /// Updates the per-video saving method preference on an existing record.
    func updateSavingMethod(on record: VideoRecord, method: SavingMethod) throws {
        record.savingMethod = method
        try context.save()
    }
}
