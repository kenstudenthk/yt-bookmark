import UIKit

/// Opens YouTube at a specific video and timestamp.
/// Primary: vnd.youtube:// (YouTube App)
/// Fallback: https://youtu.be/ (Safari)
enum DeepLinkService {

    /// Opens YouTube at the given video ID and timestamp (seconds).
    /// Automatically falls back to Safari if the YouTube app is not installed.
    @MainActor
    static func openYouTube(videoID: String, timestamp: Int) {
        let app = UIApplication.shared

        if let primary = youtubeAppURL(videoID: videoID, timestamp: timestamp),
           app.canOpenURL(primary) {
            app.open(primary)
        } else if let fallback = safariURL(videoID: videoID, timestamp: timestamp) {
            app.open(fallback)
        }
    }

    /// Parses and handles a ytbookmark:// deep link received by the main app.
    /// Returns the (videoID, timestamp) pair if valid, nil if the URL is malformed.
    static func parseIncomingDeepLink(_ url: URL) -> (videoID: String, timestamp: Int)? {
        guard
            url.scheme == "ytbookmark",
            url.host == "open",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value,
            isValidVideoID(videoID)
        else { return nil }

        let timestamp = components.queryItems?
            .first(where: { $0.name == "t" })?.value
            .flatMap(Int.init) ?? 0

        return (videoID, max(0, timestamp))
    }

    // MARK: - Private

    private static func youtubeAppURL(videoID: String, timestamp: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "vnd.youtube"
        components.host = "watch"
        components.queryItems = [
            URLQueryItem(name: "v", value: videoID),
            URLQueryItem(name: "t", value: "\(timestamp)"),
        ]
        return components.url
    }

    private static func safariURL(videoID: String, timestamp: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "youtu.be"
        components.path = "/\(videoID)"
        if timestamp > 0 {
            components.queryItems = [URLQueryItem(name: "t", value: "\(timestamp)")]
        }
        return components.url
    }

    /// videoID must match [A-Za-z0-9_-]{11}
    private static func isValidVideoID(_ id: String) -> Bool {
        id.count == 11 && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}
