import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct BookmarkWidgetBundle: WidgetBundle {
    var body: some Widget {
        BookmarkWidget()
    }
}

// MARK: - Widget

struct BookmarkWidget: Widget {
    let kind = "BookmarkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookmarkWidgetProvider()) { entry in
            BookmarkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("YT Bookmark")
        .description("Your recent YouTube bookmarks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Provider

struct BookmarkWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> BookmarkWidgetEntry {
        BookmarkWidgetEntry(date: Date(), bookmarks: WidgetBookmark.samples, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (BookmarkWidgetEntry) -> Void) {
        completion(context.isPreview ? .preview : .fromAppGroup())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookmarkWidgetEntry>) -> Void) {
        let entry = BookmarkWidgetEntry.fromAppGroup()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - Entry View (router)

struct BookmarkWidgetEntryView: View {

    @Environment(\.widgetFamily) private var family
    let entry: BookmarkWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (1 bookmark, whole widget = deep link)

private struct SmallWidgetView: View {

    let entry: BookmarkWidgetEntry

    var body: some View {
        if let bookmark = entry.bookmarks.first {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    Text("YT Bookmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Spacer()

                Text(bookmark.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(3)
                    .foregroundStyle(.primary)

                TimestampPill(label: bookmark.timestampLabel, isStart: bookmark.timestamp == 0)
            }
            .padding(14)
            .widgetURL(bookmark.deepLinkURL)
        } else {
            EmptyWidgetView()
        }
    }
}

// MARK: - Medium Widget (up to 3 bookmarks, each row = deep link)

private struct MediumWidgetView: View {

    let entry: BookmarkWidgetEntry

    var body: some View {
        if entry.bookmarks.isEmpty {
            EmptyWidgetView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    Text("YT Bookmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ForEach(entry.bookmarks.prefix(3)) { bookmark in
                    Link(destination: bookmark.deepLinkURL) {
                        HStack(spacing: 10) {
                            TimestampPill(label: bookmark.timestampLabel, isStart: bookmark.timestamp == 0)
                            Text(bookmark.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Empty state

private struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No bookmarks yet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Timestamp Pill

private struct TimestampPill: View {
    let label: String
    let isStart: Bool

    var body: some View {
        Text(label)
            .font(.caption.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isStart ? Color.secondary : Color.red, in: Capsule())
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    BookmarkWidget()
} timeline: {
    BookmarkWidgetEntry.preview
    BookmarkWidgetEntry.empty
}

#Preview(as: .systemMedium) {
    BookmarkWidget()
} timeline: {
    BookmarkWidgetEntry.preview
    BookmarkWidgetEntry.empty
}
