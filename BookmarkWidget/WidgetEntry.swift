import WidgetKit
import Foundation

// MARK: - WidgetBookmark

/// Lightweight bookmark snapshot decoded from App Group UserDefaults.
/// Mirrors the JSON written by WidgetDataService in the main app target.
struct WidgetBookmark: Codable, Identifiable {
    let videoID: String
    let title: String
    let thumbnailURL: String
    let timestamp: Int
    let platform: String

    var id: String { videoID }

    /// ytbookmark:// deep link URL for this bookmark.
    var deepLinkURL: URL {
        URL(string: "ytbookmark://open?v=\(videoID)&t=\(timestamp)&p=\(platform)")!
    }

    /// Formatted timestamp label ("Start", "m:ss", "h:mm:ss").
    var timestampLabel: String {
        if timestamp == 0 { return "Start" }
        let h = timestamp / 3600
        let m = (timestamp % 3600) / 60
        let s = timestamp % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    // MARK: - Sample data (for previews and placeholders)

    static let placeholder = WidgetBookmark(
        videoID: "dQw4w9WgXcQ",
        title: "How to build great iOS apps",
        thumbnailURL: "",
        timestamp: 312,
        platform: "youtube"
    )

    static let samples: [WidgetBookmark] = [
        WidgetBookmark(videoID: "dQw4w9WgXcQ", title: "How to build great iOS apps", thumbnailURL: "", timestamp: 312, platform: "youtube"),
        WidgetBookmark(videoID: "BV1xx411c7mD", title: "GitHub一周热点 — Rust工具集", thumbnailURL: "", timestamp: 0, platform: "bilibili"),
        WidgetBookmark(videoID: "XYZ987uvwAB", title: "Understanding SwiftData models", thumbnailURL: "", timestamp: 5610, platform: "youtube"),
    ]
}

// MARK: - BookmarkWidgetEntry

struct BookmarkWidgetEntry: TimelineEntry {
    let date: Date
    let bookmarks: [WidgetBookmark]
    let isPlaceholder: Bool

    static let empty = BookmarkWidgetEntry(date: Date(), bookmarks: [], isPlaceholder: false)
    static let preview = BookmarkWidgetEntry(date: Date(), bookmarks: WidgetBookmark.samples, isPlaceholder: false)
}

// MARK: - App Group reading

extension BookmarkWidgetEntry {
    static func fromAppGroup() -> BookmarkWidgetEntry {
        let appGroupID = "group.com.myapp.ytbookmark"
        let key = "widgetData"

        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let json = defaults.string(forKey: key),
            let data = json.data(using: .utf8),
            let bookmarks = try? JSONDecoder().decode([WidgetBookmark].self, from: data)
        else {
            return .empty
        }

        return BookmarkWidgetEntry(date: Date(), bookmarks: bookmarks, isPlaceholder: false)
    }
}
