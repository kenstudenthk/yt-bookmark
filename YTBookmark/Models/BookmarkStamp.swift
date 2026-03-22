import Foundation
import SwiftData

// Phase 5 / Future — model defined for schema stability; no UI in v1.
// Do not add stamp creation, listing, or deletion UI until Phase 5.

@Model
final class BookmarkStamp {
    var id: UUID
    var timestamp: Int
    var label: String
    var createdAt: Date
    var video: VideoRecord

    init(timestamp: Int, label: String, video: VideoRecord, createdAt: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.label = label
        self.createdAt = createdAt
        self.video = video
    }
}
