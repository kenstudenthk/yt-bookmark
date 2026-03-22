import SwiftUI
import SwiftData

struct FolderDetailView: View {

    let folder: Folder

    @Environment(\.modelContext)    private var context
    @Environment(NavigationStore.self) private var navigationStore

    @State private var viewModel = BookmarkListViewModel()

    var body: some View {
        Group {
            if folder.records.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
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
            ForEach(folder.records.sorted(by: { $0.savedAt > $1.savedAt })) { record in
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Bookmarks",
            systemImage: "bookmark.slash",
            description: Text("Move bookmarks here from the main list.")
        )
    }
}
