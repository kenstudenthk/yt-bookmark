import SwiftUI

struct BookmarkRowView: View {

    let record: VideoRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ThumbnailView(urlString: record.thumbnailURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    TimestampBadge(seconds: record.lastTimestamp)
                    Text(record.savedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.title), saved \(record.savedAt.formatted(date: .abbreviated, time: .omitted))")
    }
}

// MARK: - ThumbnailView

struct ThumbnailView: View {

    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 120, height: 68)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityHidden(true)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "play.fill")
                .foregroundStyle(.secondary)
                .font(.title3)
        }
    }
}

// MARK: - TimestampBadge

struct TimestampBadge: View {

    let seconds: Int

    var body: some View {
        Text(label)
            .font(.caption.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(seconds == 0 ? Color.secondary : Color.red, in: Capsule())
            .accessibilityLabel(seconds == 0 ? "Starts from beginning" : "Saved at \(label)")
    }

    var label: String {
        if seconds == 0 { return "Start" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
