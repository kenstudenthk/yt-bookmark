import UIKit

/// Opens YouTube or Bilibili at a specific video and timestamp.
/// Routes by platform string ("youtube" | "bilibili").
enum DeepLinkService {

    // MARK: - Open video

    /// Opens the correct video app based on the record's platform.
    @MainActor
    static func openVideo(videoID: String, timestamp: Int, platform: String) {
        switch platform {
        case "bilibili": openBilibili(videoID: videoID, timestamp: timestamp)
        default:         openYouTube(videoID: videoID, timestamp: timestamp)
        }
    }

    /// Opens YouTube at the given video ID and timestamp.
    /// Primary: vnd.youtube:// — fallback: https://youtu.be/
    @MainActor
    static func openYouTube(videoID: String, timestamp: Int) {
        let app = UIApplication.shared

        if let primary = youtubeAppURL(videoID: videoID, timestamp: timestamp),
           app.canOpenURL(primary) {
            app.open(primary)
        } else if let fallback = youtubeFallbackURL(videoID: videoID, timestamp: timestamp) {
            app.open(fallback)
        }
    }

    /// Opens Bilibili at the given BV ID and timestamp.
    /// Primary: bilibili:// — fallback: https://www.bilibili.com/video/
    @MainActor
    static func openBilibili(videoID: String, timestamp: Int) {
        let app = UIApplication.shared

        if let primary = bilibiliAppURL(videoID: videoID, timestamp: timestamp),
           app.canOpenURL(primary) {
            app.open(primary)
        } else if let fallback = bilibiliFallbackURL(videoID: videoID, timestamp: timestamp) {
            app.open(fallback)
        }
    }

    // MARK: - Incoming deep link (ytbookmark://)

    /// Parses a ytbookmark:// deep link from the widget.
    /// Returns (videoID, timestamp, platform) if valid, nil if malformed.
    static func parseIncomingDeepLink(_ url: URL) -> (videoID: String, timestamp: Int, platform: String)? {
        guard
            url.scheme == "ytbookmark",
            url.host == "open",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value,
            !videoID.isEmpty
        else { return nil }

        let platform = components.queryItems?.first(where: { $0.name == "p" })?.value ?? "youtube"

        // Validate video ID based on platform
        switch platform {
        case "bilibili":
            guard isValidBVID(videoID) else { return nil }
        default:
            guard isValidYouTubeID(videoID) else { return nil }
        }

        let timestamp = components.queryItems?
            .first(where: { $0.name == "t" })?.value
            .flatMap(Int.init) ?? 0

        return (videoID, max(0, timestamp), platform)
    }

    // MARK: - Private: YouTube URLs

    private static func youtubeAppURL(videoID: String, timestamp: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "vnd.youtube"
        c.host = "watch"
        c.queryItems = [
            URLQueryItem(name: "v", value: videoID),
            URLQueryItem(name: "t", value: "\(timestamp)"),
        ]
        return c.url
    }

    private static func youtubeFallbackURL(videoID: String, timestamp: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "https"
        c.host = "youtu.be"
        c.path = "/\(videoID)"
        if timestamp > 0 { c.queryItems = [URLQueryItem(name: "t", value: "\(timestamp)")] }
        return c.url
    }

    // MARK: - Private: Bilibili URLs

    private static func bilibiliAppURL(videoID: String, timestamp: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "bilibili"
        c.host = "video"
        c.path = "/\(videoID)"
        if timestamp > 0 { c.queryItems = [URLQueryItem(name: "t", value: "\(timestamp)")] }
        return c.url
    }

    private static func bilibiliFallbackURL(videoID: String, timestamp: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "https"
        c.host = "www.bilibili.com"
        c.path = "/video/\(videoID)"
        if timestamp > 0 { c.queryItems = [URLQueryItem(name: "t", value: "\(timestamp)")] }
        return c.url
    }

    // MARK: - Validation

    /// YouTube videoID must match [A-Za-z0-9_-]{11}
    static func isValidYouTubeID(_ id: String) -> Bool {
        id.count == 11 && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }

    /// Bilibili BV ID: BV + exactly 10 alphanumeric chars
    static func isValidBVID(_ id: String) -> Bool {
        id.count == 12 && id.hasPrefix("BV") && id.dropFirst(2).allSatisfy { $0.isLetter || $0.isNumber }
    }
}
