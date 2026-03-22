import Foundation

// MARK: - ParsedBilibiliURL

struct ParsedBilibiliURL {
    let videoID: String   // BV ID, e.g. "BV1xx411c7mD"
    let timestamp: Int    // seconds; 0 if not present or unparseable
}

// MARK: - BilibiliURLParser

/// Parses Bilibili video URLs and extracts the BV ID and optional timestamp.
///
/// Supported formats:
///   - https://www.bilibili.com/video/BVxxx
///   - https://bilibili.com/video/BVxxx
///   - https://m.bilibili.com/video/BVxxx
///   - Any of the above with ?t=SECONDS and/or other query params
///
/// NOT supported (returns nil):
///   - https://b23.tv/xxx  (short URL — must be resolved to a bilibili.com URL first)
///   - av-number format (https://bilibili.com/video/av123456)
///   - Non-video paths (bangumi, space, etc.)
enum BilibiliURLParser {

    private static let validHosts: Set<String> = [
        "bilibili.com", "www.bilibili.com", "m.bilibili.com"
    ]

    static func parse(_ urlString: String) -> ParsedBilibiliURL? {
        guard
            let url = URL(string: urlString),
            let host = url.host,
            validHosts.contains(host)
        else { return nil }

        guard let videoID = extractVideoID(from: url) else { return nil }

        let timestamp = extractTimestamp(from: url)
        return ParsedBilibiliURL(videoID: videoID, timestamp: timestamp)
    }

    // MARK: - Private

    /// Extracts and validates the BV ID from the URL path.
    /// Path must contain /video/BVxxxxxxxxxx (BV + exactly 10 alphanumeric chars).
    private static func extractVideoID(from url: URL) -> String? {
        let components = url.pathComponents
        // Find the index of "video" in path, then take the next component
        guard
            let videoIndex = components.firstIndex(of: "video"),
            videoIndex + 1 < components.count
        else { return nil }

        let rawID = components[videoIndex + 1]

        // Validate: BV + exactly 10 alphanumeric characters
        guard
            rawID.count == 12,
            rawID.hasPrefix("BV"),
            rawID.dropFirst(2).allSatisfy({ $0.isLetter || $0.isNumber })
        else { return nil }

        return rawID
    }

    /// Extracts the `t` query parameter as seconds.
    /// Returns 0 if absent, non-integer, or negative.
    private static func extractTimestamp(from url: URL) -> Int {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let tValue = components.queryItems?.first(where: { $0.name == "t" })?.value,
            let seconds = Int(tValue),
            seconds >= 0
        else { return 0 }
        return seconds
    }
}
