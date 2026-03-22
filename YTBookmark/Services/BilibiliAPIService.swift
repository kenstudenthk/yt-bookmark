import Foundation

struct BilibiliMetadata {
    let title: String
    let thumbnailURL: String
}

/// Fetches video title and thumbnail from the Bilibili public API.
/// No API key required. Returns nil on any failure.
enum BilibiliAPIService {

    private static let baseURL = "https://api.bilibili.com/x/web-interface/view"

    /// Fetches metadata for the given BV ID.
    /// Pass a custom `session` in tests to avoid real network calls.
    static func fetchMetadata(bvid: String, session: URLSession = .shared) async -> BilibiliMetadata? {
        guard let url = buildURL(bvid: bvid) else { return nil }

        var request = URLRequest(url: url)
        // Bilibili API requires a browser-like User-Agent to return data
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://www.bilibili.com", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            return decode(data: data)
        } catch {
            return nil
        }
    }

    // MARK: - Private

    private static func buildURL(bvid: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [URLQueryItem(name: "bvid", value: bvid)]
        return components?.url
    }

    private static func decode(data: Data) -> BilibiliMetadata? {
        guard
            let response = try? JSONDecoder().decode(BilibiliAPIResponse.self, from: data),
            response.code == 0,
            let data = response.data,
            !data.title.isEmpty
        else { return nil }

        let thumbnailURL = normalizeURL(data.pic)
        return BilibiliMetadata(title: data.title, thumbnailURL: thumbnailURL)
    }

    /// Converts protocol-relative URLs (//i2.hdslb.com/...) to https:
    private static func normalizeURL(_ raw: String) -> String {
        if raw.hasPrefix("//") { return "https:" + raw }
        return raw
    }
}

// MARK: - Codable response types

private struct BilibiliAPIResponse: Decodable {
    let code: Int
    let data: BilibiliVideoData?
}

private struct BilibiliVideoData: Decodable {
    let title: String
    let pic: String
}
