import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \VideoRecord.folder)
    var records: [VideoRecord]

    init(name: String, colorHex: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.records = []
    }

    /// The six preset folder colours.
    static let presetColors: [String] = [
        "#FF6B6B",
        "#4ECDC4",
        "#45B7D1",
        "#96CEB4",
        "#FFEAA7",
        "#DDA0DD",
    ]
}
