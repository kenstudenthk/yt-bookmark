import SwiftUI
import SwiftData

struct SearchView: View {

    @Query(sort: \VideoRecord.savedAt, order: .reverse)
    private var allRecords: [VideoRecord]

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = SearchViewModel()
    @State private var listViewModel = BookmarkListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.query.isEmpty {
                    promptState
                } else if viewModel.results(from: allRecords).isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search bookmarks")
            .onChange(of: viewModel.query) { viewModel.scheduleDebounce() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { listViewModel.errorMessage != nil },
                set: { if !$0 { listViewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { listViewModel.errorMessage = nil }
            } message: {
                Text(listViewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(viewModel.results(from: allRecords)) { record in
                BookmarkRowView(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.query = ""
                        dismiss()
                        listViewModel.openBookmark(record)
                    }
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Prompt State

    private var promptState: some View {
        ContentUnavailableView(
            "Search Bookmarks",
            systemImage: "magnifyingglass",
            description: Text("Type a title to find saved videos.")
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView.search(text: viewModel.debouncedQuery)
    }
}
