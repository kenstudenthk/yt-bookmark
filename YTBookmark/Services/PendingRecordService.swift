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

        // Fetch metadata from YouTube API
        let metadata = await YouTubeAPIService.fetchMetadata(videoID: pending.videoID)

        let title         = metadata?.title        ?? pending.videoID
        let thumbnailURL  = metadata?.thumbnailURL ?? VideoRecord.fallbackThumbnailURL(for: pending.videoID)
        let needsEnrich   = metadata == nil

        do {
            try repository.createRecord(
                videoID:         pending.videoID,
                title:           title,
                thumbnailURL:    thumbnailURL,
                timestamp:       pending.timestamp,
                note:            pending.note,
                needsEnrichment: needsEnrich
            )
            await refreshWidgetData()
            await showToast("Bookmark saved!")
        } catch {
            // SwiftData save failed — record is lost but pendingRecord is already deleted.
            // Nothing more we can do here; error would need to surface via a separate mechanism.
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
            guard let metadata = await YouTubeAPIService.fetchMetadata(videoID: record.videoID)
            else { continue }

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
