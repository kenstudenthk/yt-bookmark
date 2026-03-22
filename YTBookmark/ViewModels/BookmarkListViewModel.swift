import SwiftUI
import SwiftData
import Observation

@Observable
final class BookmarkListViewModel {

    var errorMessage: String?

    // MARK: - Actions

    @MainActor
    func openBookmark(_ record: VideoRecord) {
        DeepLinkService.openVideo(videoID: record.videoID, timestamp: record.lastTimestamp, platform: record.platform)
    }

    func deleteRecord(_ record: VideoRecord, context: ModelContext) {
        do {
            try BookmarkRepository(context: context).deleteRecord(record)
            refreshWidgetData(context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func refreshWidgetData(context: ModelContext) {
        do {
            let recent = try BookmarkRepository(context: context).fetchRecentRecords(limit: 5)
            WidgetDataService.update(with: recent)
        } catch {}
    }
}
