import Foundation
import SwiftData

@Model
final class VideoRecord {
    var id: UUID
    var videoID: String
    var title: String
    var thumbnailURL: String
    var savedAt: Date
    var lastTimestamp: Int
    var note: String
    var needsEnrichment: Bool
    var folder: Folder?

    @Relationship(deleteRule: .cascade, inverse: \BookmarkStamp.video)
    var stamps: [BookmarkStamp]

    init(
        videoID: String,
        title: String,
        thumbnailURL: String? = nil,
        savedAt: Date = Date(),
        lastTimestamp: Int = 0,
        note: String = "",
        needsEnrichment: Bool = false,
        folder: Folder? = nil
    ) {
        self.id = UUID()
        self.videoID = videoID
        self.title = title
        self.thumbnailURL = thumbnailURL ?? VideoRecord.fallbackThumbnailURL(for: videoID)
        self.savedAt = savedAt
        self.lastTimestamp = lastTimestamp
        self.note = note
        self.needsEnrichment = needsEnrichment
        self.folder = folder
        self.stamps = []
    }

    /// Returns the mqdefault.jpg thumbnail URL for a given YouTube video ID.
    /// Use this whenever the YouTube Data API fails or returns no thumbnail.
    static func fallbackThumbnailURL(for videoID: String) -> String {
        "https://img.youtube.com/vi/\(videoID)/mqdefault.jpg"
    }
}
