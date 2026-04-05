import Foundation
import Observation

// MARK: - ParsedVideoURL

struct ParsedVideoURL {
    let videoID: String
    let timestamp: Int
    let platform: String  // "youtube" | "bilibili"
}

// MARK: - ShareState

enum ShareState {
    case loading
    case invalid(message: String)
    case ready(parsed: ParsedVideoURL)
    case saving
}

// MARK: - ShareViewModel

@Observable
final class ShareViewModel {

    // MARK: - State

    var state: ShareState = .loading
    var note: String = ""
    var isDuplicate: Bool = false
    var overrideExisting: Bool = true

    // Alert flags
    var showPendingRecordWarning = false
    var showSaveError = false
    var saveErrorMessage = ""

    // MARK: - Load

    /// Extracts the first URL from the extension context, resolves b23.tv short links,
    /// then tries YouTube parser followed by Bilibili parser.
    func loadURL(from context: NSExtensionContext) async {
        for case let item as NSExtensionItem in context.inputItems {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier("public.url"),
                   let url = try? await provider.loadItem(forTypeIdentifier: "public.url") as? URL {
                    let resolved = await resolveIfShortURL(url.absoluteString)
                    await MainActor.run { process(urlString: resolved) }
                    return
                }
                // Bilibili shares text like "【title-哔哩哔哩】 https://b23.tv/xxx"
                if provider.hasItemConformingToTypeIdentifier("public.text"),
                   let text = try? await provider.loadItem(forTypeIdentifier: "public.text") as? String {
                    let urlString = extractURL(from: text) ?? text
                    let resolved = await resolveIfShortURL(urlString)
                    await MainActor.run { process(urlString: resolved) }
                    return
                }
            }
        }
        await MainActor.run {
            state = .invalid(message: "No URL found in the shared content.")
        }
    }

    // MARK: - Save

    func requestSave(context: NSExtensionContext) {
        guard case .ready = state else { return }
        if PendingRecord.exists() {
            showPendingRecordWarning = true
        } else {
            performSave(context: context)
        }
    }

    func confirmOverwriteAndSave(context: NSExtensionContext) {
        performSave(context: context)
    }

    // MARK: - Cancel

    func cancel(context: NSExtensionContext) {
        context.cancelRequest(withError: NSError(
            domain: "com.myapp.ytbookmark.share",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
        ))
    }

    // MARK: - Private: Parsing

    private func process(urlString: String) {
        if let parsed = YouTubeURLParser.parse(urlString) {
            let videoID = parsed.videoID
            state = .ready(parsed: ParsedVideoURL(
                videoID: videoID,
                timestamp: parsed.timestamp,
                platform: "youtube"
            ))
            isDuplicate = savedVideoIDs().contains(videoID)
            return
        }
        if let parsed = BilibiliURLParser.parse(urlString) {
            let videoID = parsed.videoID
            state = .ready(parsed: ParsedVideoURL(
                videoID: videoID,
                timestamp: parsed.timestamp,
                platform: "bilibili"
            ))
            isDuplicate = savedVideoIDs().contains(videoID)
            return
        }
        state = .invalid(message: "Share a YouTube or Bilibili video link to bookmark it.")
    }

    /// Extracts the first https:// URL from a string (handles rich share text).
    private func extractURL(from text: String) -> String? {
        let pattern = #"https?://[^\s]+"#
        guard let range = text.range(of: pattern, options: .regularExpression) else { return nil }
        return String(text[range])
    }

    /// Follows redirects for b23.tv short URLs; returns original string for all other hosts.
    private func resolveIfShortURL(_ urlString: String) async -> String {
        guard
            let url = URL(string: urlString),
            url.host?.hasSuffix("b23.tv") == true
        else { return urlString }

        // HEAD request follows redirects; final response URL is the resolved destination.
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        if let (_, response) = try? await URLSession.shared.data(for: request) {
            return response.url?.absoluteString ?? urlString
        }
        return urlString
    }

    // MARK: - Private: Duplicate Detection

    /// Reads the saved video ID set written by the main app into App Group UserDefaults.
    private func savedVideoIDs() -> Set<String> {
        guard
            let defaults = UserDefaults(suiteName: "group.com.myapp.ytbookmark"),
            let json = defaults.string(forKey: "savedVideoIDs"),
            let data = json.data(using: .utf8),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(ids)
    }

    // MARK: - Private: Save

    private func performSave(context: NSExtensionContext) {
        guard case .ready(let parsed) = state else { return }
        state = .saving

        let savingMethod: String? = isDuplicate ? (overrideExisting ? "cover" : "addNew") : nil
        let record = PendingRecord(
            videoID: parsed.videoID,
            rawURL: currentRawURL(parsed: parsed),
            timestamp: parsed.timestamp,
            savedAt: Date(),
            note: String(note.prefix(500)),
            platform: parsed.platform,
            savingMethod: savingMethod
        )

        do {
            try record.write()
            context.completeRequest(returningItems: nil)
        } catch {
            state = .ready(parsed: parsed)
            saveErrorMessage = "Failed to save. Please try again."
            showSaveError = true
        }
    }

    private func currentRawURL(parsed: ParsedVideoURL) -> String {
        switch parsed.platform {
        case "bilibili":
            return "https://www.bilibili.com/video/\(parsed.videoID)"
        default:
            var components = URLComponents()
            components.scheme = "https"
            components.host = "youtu.be"
            components.path = "/\(parsed.videoID)"
            if parsed.timestamp > 0 {
                components.queryItems = [URLQueryItem(name: "t", value: "\(parsed.timestamp)")]
            }
            return components.url?.absoluteString ?? "https://youtu.be/\(parsed.videoID)"
        }
    }
}
