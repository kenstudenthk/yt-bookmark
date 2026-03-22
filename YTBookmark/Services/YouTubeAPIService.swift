import Foundation

struct VideoMetadata {
    let title: String
    let thumbnailURL: String
}

/// Fetches video title and thumbnail from the YouTube Data API v3.
/// Returns nil on any failure — callers should set needsEnrichment = true in that case.
enum YouTubeAPIService {

    private static let baseURL = "https://www.googleapis.com/youtube/v3/videos"

    private static var apiKey: String {
        let key = Bundle.main.infoDictionary?["YouTubeAPIKey"] as? String ?? ""
        #if DEBUG
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isTesting && (key.isEmpty || key == "YOUR_KEY_HERE") {
            fatalError("YouTubeAPIKey is missing from Info.plist. Add it to Config.xcconfig.")
        }
        #endif
        return key
    }

    /// Fetches title and thumbnail for the given YouTube video ID.
    /// Returns nil on network error, quota error, empty response, or any other failure.
    /// Pass a custom `session` in tests to avoid real network calls.
    static func fetchMetadata(videoID: String, session: URLSession = .shared) async -> VideoMetadata? {
        guard let url = buildURL(videoID: videoID) else { return nil }

        do {
            let (data, response) = try await session.data(from: url)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            return decode(data: data, videoID: videoID)
        } catch {
            return nil
        }
    }

    // MARK: - Private

    private static func buildURL(videoID: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "id",   value: videoID),
            URLQueryItem(name: "key",  value: apiKey),
        ]
        return components?.url
    }

    private static func decode(data: Data, videoID: String) -> VideoMetadata? {
        guard
            let response = try? JSONDecoder().decode(YouTubeAPIResponse.self, from: data),
            let item = response.items.first,
            !item.snippet.title.isEmpty
        else { return nil }

        let thumbnailURL = item.snippet.thumbnails.medium?.url
            ?? item.snippet.thumbnails.high?.url
            ?? item.snippet.thumbnails.default?.url
            ?? VideoRecord.fallbackThumbnailURL(for: videoID)

        return VideoMetadata(
            title: item.snippet.title,
            thumbnailURL: thumbnailURL
        )
    }
}

// MARK: - Codable response types

private struct YouTubeAPIResponse: Decodable {
    let items: [YouTubeAPIItem]
}

private struct YouTubeAPIItem: Decodable {
    let snippet: YouTubeSnippet
}

private struct YouTubeSnippet: Decodable {
    let title: String
    let thumbnails: YouTubeThumbnails
}

private struct YouTubeThumbnails: Decodable {
    let `default`: YouTubeThumbnail?
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
}

private struct YouTubeThumbnail: Decodable {
    let url: String
}
