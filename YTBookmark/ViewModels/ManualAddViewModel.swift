import Observation
import Foundation

@Observable
final class ManualAddViewModel {
    var urlInput: String = ""
    var note: String = ""
    var state: ManualAddState = .idle

    enum ManualAddState: Equatable {
        case idle
        case loading
        case success
        case error(String)
    }

    @MainActor
    func submit(repository: BookmarkRepository, conflictStore: ConflictStore) async {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, URL(string: trimmed) != nil else {
            state = .error("请输入有效的 URL")
            return
        }

        state = .loading

        do {
            let defaultFolder: Folder? = {
                guard let id = UserPreferences.defaultFolderID() else { return nil }
                return try? repository.fetchFolder(byID: id)
            }()

            if let parsed = YouTubeURLParser.parse(trimmed) {
                let meta = await YouTubeAPIService.fetchMetadata(videoID: parsed.videoID)
                let title = meta?.title ?? ""
                let thumbnailURL = meta?.thumbnailURL ?? VideoRecord.fallbackThumbnailURL(for: parsed.videoID)
                let needsEnrichment = (meta == nil)
                try await saveRecord(
                    videoID: parsed.videoID,
                    title: title,
                    thumbnailURL: thumbnailURL,
                    timestamp: parsed.timestamp,
                    needsEnrichment: needsEnrichment,
                    platform: "youtube",
                    defaultFolder: defaultFolder,
                    repository: repository,
                    conflictStore: conflictStore
                )
            } else if let parsed = BilibiliURLParser.parse(trimmed) {
                let meta = await BilibiliAPIService.fetchMetadata(bvid: parsed.videoID)
                let title = meta?.title ?? ""
                let thumbnailURL = meta?.thumbnailURL ?? ""
                let needsEnrichment = (meta == nil)
                try await saveRecord(
                    videoID: parsed.videoID,
                    title: title,
                    thumbnailURL: thumbnailURL,
                    timestamp: parsed.timestamp,
                    needsEnrichment: needsEnrichment,
                    platform: "bilibili",
                    defaultFolder: defaultFolder,
                    repository: repository,
                    conflictStore: conflictStore
                )
            } else {
                state = .error("无法识别的链接格式，请检查后重试")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    @MainActor
    private func saveRecord(
        videoID: String,
        title: String,
        thumbnailURL: String,
        timestamp: Int,
        needsEnrichment: Bool,
        platform: String,
        defaultFolder: Folder?,
        repository: BookmarkRepository,
        conflictStore: ConflictStore
    ) async throws {
        if let existing = try repository.findFirstRecord(videoID: videoID) {
            switch existing.savingMethod {
            case .cover:
                try repository.coverRecord(existing, timestamp: timestamp, note: note)
                state = .success
            case .addNew:
                _ = try repository.createRecord(
                    videoID: videoID,
                    title: title,
                    thumbnailURL: thumbnailURL,
                    timestamp: timestamp,
                    note: note,
                    needsEnrichment: needsEnrichment,
                    folder: defaultFolder,
                    platform: platform
                )
                state = .success
            case .ask:
                let incoming = IncomingBookmark(
                    videoID: videoID,
                    title: title,
                    thumbnailURL: thumbnailURL,
                    timestamp: timestamp,
                    note: note,
                    needsEnrichment: needsEnrichment,
                    platform: platform,
                    folder: defaultFolder
                )
                conflictStore.raise(DuplicateConflict(incoming: incoming, existing: existing))
                state = .idle  // Don't close sheet — conflict sheet will appear
            }
        } else {
            _ = try repository.createRecord(
                videoID: videoID,
                title: title,
                thumbnailURL: thumbnailURL,
                timestamp: timestamp,
                note: note,
                needsEnrichment: needsEnrichment,
                folder: defaultFolder,
                platform: platform
            )
            state = .success
        }
    }
}
