import SwiftUI
import SwiftData

// MARK: - Navigation destinations

enum NavigationDestination: Hashable {
    case folders
    case folderDetail(Folder)
}

// MARK: - BookmarkListView

struct BookmarkListView: View {

    @Query(sort: \VideoRecord.savedAt, order: .reverse)
    private var records: [VideoRecord]

    @Environment(\.modelContext)    private var context
    @Environment(NavigationStore.self) private var navigationStore

    @State private var viewModel = BookmarkListViewModel()

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("YT Bookmark")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbar }
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .folders:
                FolderListView()
            case .folderDetail(let folder):
                FolderDetailView(folder: folder)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(records) { record in
                BookmarkRowView(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.openBookmark(record) }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteRecord(record, context: context)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            navigationStore.activeSheet = .editNote(record)
                        } label: {
                            Label("Edit Note", systemImage: "pencil")
                        }
                        Button {
                            navigationStore.activeSheet = .moveToFolder(record)
                        } label: {
                            Label("Move to Folder", systemImage: "folder")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .animation(.default, value: records)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Bookmarks Yet",
            systemImage: "bookmark.slash",
            description: Text("Share a YouTube video to get started.")
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink(value: NavigationDestination.folders) {
                Image(systemName: "folder.badge.plus")
                    .accessibilityLabel("Folders")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                navigationStore.activeSheet = .search
            } label: {
                Image(systemName: "magnifyingglass")
                    .accessibilityLabel("Search")
            }
        }
    }
}
