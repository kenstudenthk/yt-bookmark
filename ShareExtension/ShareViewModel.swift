import Foundation
import Observation

enum ShareState {
    case loading
    case invalid(message: String)
    case ready(parsed: ParsedYouTubeURL)
    case saving
}

@Observable
final class ShareViewModel {

    // MARK: - State

    var state: ShareState = .loading
    var note: String = ""

    // Alert flags
    var showPendingRecordWarning = false
    var showSaveError = false
    var saveErrorMessage = ""

    // MARK: - Load

    /// Extracts the first YouTube URL from the extension context and parses it.
    func loadURL(from context: NSExtensionContext) async {
        for case let item as NSExtensionItem in context.inputItems {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier("public.url"),
                   let url = try? await provider.loadItem(forTypeIdentifier: "public.url") as? URL {
                    await MainActor.run { process(urlString: url.absoluteString) }
                    return
                }
                // Safari sometimes sends public.text instead of public.url
                if provider.hasItemConformingToTypeIdentifier("public.text"),
                   let text = try? await provider.loadItem(forTypeIdentifier: "public.text") as? String {
                    await MainActor.run { process(urlString: text) }
                    return
                }
            }
        }
        await MainActor.run {
            state = .invalid(message: "No URL found in the shared content.")
        }
    }

    // MARK: - Save

    /// Called when user taps Save. Checks for existing record first.
    func requestSave(context: NSExtensionContext) {
        guard case .ready = state else { return }
        if PendingRecord.exists() {
            showPendingRecordWarning = true
        } else {
            performSave(context: context)
        }
    }

    /// Called after user confirms overwrite of existing pending record.
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

    // MARK: - Private

    private func process(urlString: String) {
        guard let parsed = YouTubeURLParser.parse(urlString) else {
            state = .invalid(message: "Not a YouTube link.")
            return
        }
        state = .ready(parsed: parsed)
    }

    private func performSave(context: NSExtensionContext) {
        guard case .ready(let parsed) = state else { return }
        state = .saving

        let record = PendingRecord(
            videoID: parsed.videoID,
            rawURL: currentRawURL(parsed: parsed),
            timestamp: parsed.timestamp,
            savedAt: Date(),
            note: String(note.prefix(500))
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

    private func currentRawURL(parsed: ParsedYouTubeURL) -> String {
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
