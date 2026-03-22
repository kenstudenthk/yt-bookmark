import Foundation
import WidgetKit

/// Writes the top-5 recent bookmarks to App Group UserDefaults for the widget to read.
/// Call after every SwiftData modification that affects the bookmark list.
enum WidgetDataService {

    static let userDefaultsKey = "widgetData"
    private static let appGroupID = "group.com.myapp.ytbookmark"
    private static let maxItems = 5

    /// Encodes the given records (max 5) and writes them to the shared App Group,
    /// then triggers an immediate widget timeline reload.
    static func update(with records: [VideoRecord]) {
        let entries = records
            .prefix(maxItems)
            .map { WidgetEntry(from: $0) }

        guard
            let data = try? JSONEncoder().encode(entries),
            let json = String(data: data, encoding: .utf8),
            let defaults = UserDefaults(suiteName: appGroupID)
        else { return }

        defaults.set(json, forKey: userDefaultsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reads widget entries from the App Group (used by the widget target).
    static func read() -> [WidgetEntry] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let json = defaults.string(forKey: userDefaultsKey),
            let data = json.data(using: .utf8),
            let entries = try? JSONDecoder().decode([WidgetEntry].self, from: data)
        else { return [] }

        return entries
    }
}

// MARK: - WidgetEntry

/// Lightweight snapshot of a VideoRecord for the widget.
/// Stored in App Group UserDefaults — no SwiftData access from the widget.
struct WidgetEntry: Codable {
    let videoID: String
    let title: String
    let thumbnailURL: String
    let timestamp: Int

    init(from record: VideoRecord) {
        videoID     = record.videoID
        title       = record.title
        thumbnailURL = record.thumbnailURL
        timestamp   = record.lastTimestamp
    }
}
