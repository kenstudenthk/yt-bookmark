import WidgetKit
import SwiftUI

@main
struct BookmarkWidgetBundle: WidgetBundle {
    var body: some Widget {
        BookmarkWidget()
    }
}

struct BookmarkWidget: Widget {
    let kind: String = "BookmarkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookmarkWidgetProvider()) { entry in
            Text(entry.date.formatted())
        }
        .configurationDisplayName("YT Bookmark")
        .description("Your recent YouTube bookmarks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BookmarkWidgetEntry: TimelineEntry {
    let date: Date
}

struct BookmarkWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BookmarkWidgetEntry {
        BookmarkWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (BookmarkWidgetEntry) -> Void) {
        completion(BookmarkWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookmarkWidgetEntry>) -> Void) {
        let entry = BookmarkWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date(timeIntervalSinceNow: 1800)))
        completion(timeline)
    }
}
