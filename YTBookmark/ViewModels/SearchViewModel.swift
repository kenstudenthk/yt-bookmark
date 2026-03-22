import SwiftUI
import Observation

@Observable
final class SearchViewModel {

    var query = ""
    var debouncedQuery = ""

    private var debounceTask: Task<Void, Never>?

    // Called from the view whenever `query` changes.
    func scheduleDebounce() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            debouncedQuery = query
        }
    }

    // MARK: - Filtering

    func results(from records: [VideoRecord]) -> [VideoRecord] {
        let trimmed = debouncedQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return records }
        return records.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
