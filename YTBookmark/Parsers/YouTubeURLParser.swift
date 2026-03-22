import Foundation

struct ParsedYouTubeURL {
    let videoID: String   // Always matches [A-Za-z0-9_-]{11}
    let timestamp: Int    // Seconds; 0 if not present or unparseable
}

enum YouTubeURLParser {

    // Matches exactly 11 base64url characters
    private static let videoIDPattern = /^[A-Za-z0-9_\-]{11}$/

    // Matches XhYmZs formatted time; at least one group must be present
    private static let formattedTimePattern = /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$/

    /// Parses a YouTube URL string and returns a `ParsedYouTubeURL`, or `nil` if unsupported.
    static func parse(_ urlString: String) -> ParsedYouTubeURL? {
        guard
            !urlString.isEmpty,
            let url = URL(string: urlString),
            let host = url.host?.lowercased()
        else { return nil }

        // Normalise host: strip leading "www."
        let normalisedHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host

        switch normalisedHost {
        case "youtu.be":
            return parseShortURL(url)
        case "youtube.com":
            return parseLongURL(url)
        default:
            return nil
        }
    }

    // MARK: - Private

    /// Parses https://youtu.be/{videoID}?t=...
    private static func parseShortURL(_ url: URL) -> ParsedYouTubeURL? {
        // videoID is the path component (drop leading "/")
        let path = url.path
        let rawID = path.hasPrefix("/") ? String(path.dropFirst()) : path

        guard isValidVideoID(rawID) else { return nil }

        let timestamp = extractTimestamp(from: url)
        return ParsedYouTubeURL(videoID: rawID, timestamp: timestamp)
    }

    /// Parses https://youtube.com/watch?v={videoID}&t=...
    private static func parseLongURL(_ url: URL) -> ParsedYouTubeURL? {
        // Must be /watch path; /shorts and others return nil
        guard url.path == "/watch" else { return nil }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard
            let rawID = components?.queryItems?.first(where: { $0.name == "v" })?.value,
            isValidVideoID(rawID)
        else { return nil }

        let timestamp = extractTimestamp(from: url)
        return ParsedYouTubeURL(videoID: rawID, timestamp: timestamp)
    }

    /// Returns true if the string matches [A-Za-z0-9_-]{11} exactly.
    private static func isValidVideoID(_ id: String) -> Bool {
        (try? videoIDPattern.wholeMatch(in: id)) != nil
    }

    /// Extracts the `t=` parameter as seconds. Returns 0 for missing or unparseable values.
    private static func extractTimestamp(from url: URL) -> Int {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let tValue = components?.queryItems?.first(where: { $0.name == "t" })?.value,
              !tValue.isEmpty
        else { return 0 }

        // Try plain integer first
        if let seconds = Int(tValue) {
            return seconds
        }

        // Try XhYmZs formatted time
        return parseFormattedTime(tValue) ?? 0
    }

    /// Converts "1h3m30s" → 5610. Returns nil if no component matched (empty/invalid string).
    private static func parseFormattedTime(_ value: String) -> Int? {
        guard let match = try? formattedTimePattern.wholeMatch(in: value) else { return nil }

        let hours   = match.output.1.flatMap { Int($0) } ?? 0
        let minutes = match.output.2.flatMap { Int($0) } ?? 0
        let seconds = match.output.3.flatMap { Int($0) } ?? 0

        // Require at least one component to be non-zero to avoid matching empty string
        guard hours > 0 || minutes > 0 || seconds > 0 else { return nil }

        return hours * 3600 + minutes * 60 + seconds
    }
}
