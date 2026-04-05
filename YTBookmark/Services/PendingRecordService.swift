import Foundation
import Observation

/// Triggered on scenePhase == .active.
/// 1. Ingests any pending record written by the Share Extension.
/// 2. Retries enrichment for records where needsEnrichment == true.
@Observable
final class PendingRecordService {

    /// Non-nil while the success toast should be visible.
    var toastMessage: String? = nil

    private let repository: BookmarkRepository

    /// Optional — set by the app after init to enable conflict-sheet routing.
    /// If nil, duplicate detection still runs but `.ask` falls back to `.addNew` silently.
    var conflictStore: ConflictStore?

    init(repository: BookmarkRepository) {
        self.repository = repository
    }

    // MARK: - Public

    /// Call on every scenePhase == .active transition.
    func ingestAndRetry() async {
        await ingestPendingRecord()
        await retryEnrichment()
    }

    // MARK: - Ingest

    private func ingestPendingRecord() async {
        // Read before deleting so we have the data
        guard let pending = PendingRecord.read() else { return }

        // Delete FIRST — prevents duplicate ingestion if app foregrounds
        // again during a slow API call (concurrency guard from SPEC.md §7)
        PendingRecord.delete()

        // Fetch metadata from the correct platform API
        let (title, thumbnailURL, needsEnrich) = await fetchMetadata(for: pending)

        do {
            if let existing = try repository.findFirstRecord(videoID: pending.videoID) {
                // Duplicate detected — route based on the per-video saving preference
                switch existing.savingMethod {
                case .cover:
                    try repository.coverRecord(existing, timestamp: pending.timestamp, note: pending.note)
                    await refreshWidgetData()
                    await showToast("Bookmark updated!")

                case .addNew:
                    let defaultFolder = UserPreferences.defaultFolderID()
                        .flatMap { try? repository.fetchFolder(byID: $0) }
                    _ = try repository.createRecord(
                        videoID:         pending.videoID,
                        title:           title,
                        thumbnailURL:    thumbnailURL,
                        timestamp:       pending.timestamp,
                        note:            pending.note,
                        needsEnrichment: needsEnrich,
                        folder:          defaultFolder,
                        platform:        pending.platform
                    )
                    await refreshWidgetData()
                    await showToast("Bookmark saved!")

                case .ask:
                    let defaultFolder = UserPreferences.defaultFolderID()
                        .flatMap { try? repository.fetchFolder(byID: $0) }
                    let incoming = IncomingBookmark(
                        videoID:         pending.videoID,
                        title:           title,
                        thumbnailURL:    thumbnailURL,
                        timestamp:       pending.timestamp,
                        note:            pending.note,
                        needsEnrichment: needsEnrich,
                        platform:        pending.platform,
                        folder:          defaultFolder
                    )
                    if let store = conflictStore {
                        await MainActor.run { store.raise(DuplicateConflict(incoming: incoming, existing: existing)) }
                    } else {
                        // No conflict UI available — fall back to addNew silently
                        _ = try repository.createRecord(
                            videoID:         pending.videoID,
                            title:           title,
                            thumbnailURL:    thumbnailURL,
                            timestamp:       pending.timestamp,
                            note:            pending.note,
                            needsEnrichment: needsEnrich,
                            folder:          defaultFolder,
                            platform:        pending.platform
                        )
                        await refreshWidgetData()
                        await showToast("Bookmark saved!")
                    }
                }
            } else {
                // No duplicate — apply default folder and create
                let defaultFolder = UserPreferences.defaultFolderID()
                    .flatMap { try? repository.fetchFolder(byID: $0) }
                _ = try repository.createRecord(
                    videoID:         pending.videoID,
                    title:           title,
                    thumbnailURL:    thumbnailURL,
                    timestamp:       pending.timestamp,
                    note:            pending.note,
                    needsEnrichment: needsEnrich,
                    folder:          defaultFolder,
                    platform:        pending.platform
                )
                await refreshWidgetData()
                await showToast("Bookmark saved!")
            }
        } catch {
            // SwiftData save failed — record is lost but pendingRecord is already deleted.
            // Nothing more we can do here; error would need to surface via a separate mechanism.
        }
    }

    // MARK: - Metadata Fetch (platform-aware)

    /// Returns (title, thumbnailURL, needsEnrichment) for the given pending record.
    private func fetchMetadata(for pending: PendingRecord) async -> (String, String, Bool) {
        if pending.platform == "bilibili" {
            if let m = await BilibiliAPIService.fetchMetadata(bvid: pending.videoID) {
                return (m.title, m.thumbnailURL, false)
            }
            return (pending.videoID, "", true)
        } else {
            if let m = await YouTubeAPIService.fetchMetadata(videoID: pending.videoID) {
                return (m.title, m.thumbnailURL, false)
            }
            return (pending.videoID, VideoRecord.fallbackThumbnailURL(for: pending.videoID), true)
        }
    }

    // MARK: - Enrichment Retry

    private func retryEnrichment() async {
        let records: [VideoRecord]
        do {
            records = try repository.fetchRecordsNeedingEnrichment()
        } catch {
            return
        }

        guard !records.isEmpty else { return }

        var anyUpdated = false
        for record in records {
            let metadata: (title: String, thumbnailURL: String)?
            if record.platform == "bilibili" {
                if let m = await BilibiliAPIService.fetchMetadata(bvid: record.videoID) {
                    metadata = (m.title, m.thumbnailURL)
                } else {
                    metadata = nil
                }
            } else {
                if let m = await YouTubeAPIService.fetchMetadata(videoID: record.videoID) {
                    metadata = (m.title, m.thumbnailURL)
                } else {
                    metadata = nil
                }
            }

            guard let metadata else { continue }

            do {
                try repository.applyEnrichment(
                    to: record,
                    title: metadata.title,
                    thumbnailURL: metadata.thumbnailURL
                )
                anyUpdated = true
            } catch {
                continue
            }
        }

        if anyUpdated {
            await refreshWidgetData()
        }
    }

    // MARK: - Helpers

    private func refreshWidgetData() async {
        do {
            let recent = try repository.fetchRecentRecords(limit: 5)
            WidgetDataService.update(with: recent)
            let allIDs = try repository.fetchAllRecords().map { $0.videoID }
            WidgetDataService.updateSavedVideoIDs(allIDs)
        } catch {}
    }

    @MainActor
    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            toastMessage = nil
        }
    }
}
