import SwiftUI
import SwiftData

struct FolderListView: View {

    @Query(sort: \Folder.createdAt, order: .forward)
    private var folders: [Folder]

    @Environment(\.modelContext) private var context

    @State private var viewModel = FolderListViewModel()
    @State private var folderPendingDelete: Folder?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            if folders.isEmpty {
                emptyState
            } else {
                grid
            }
        }
        .navigationTitle("Folders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            CreateFolderSheet { name, colorHex in
                viewModel.createFolder(name: name, colorHex: colorHex, context: context)
            }
        }
        .alert(
            "Delete \"\(folderPendingDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { folderPendingDelete != nil },
                set: { if !$0 { folderPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { folderPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let folder = folderPendingDelete {
                    viewModel.deleteFolder(folder, context: context)
                    folderPendingDelete = nil
                }
            }
        } message: {
            Text("Bookmarks will be moved to Uncategorised.")
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

    // MARK: - Grid

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(folders) { folder in
                    NavigationLink(value: NavigationDestination.folderDetail(folder)) {
                        FolderCardView(folder: folder)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            folderPendingDelete = folder
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Folders Yet",
            systemImage: "folder.badge.plus",
            description: Text("Tap + to create your first folder.")
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.isShowingCreateSheet = true
            } label: {
                Image(systemName: "plus")
                    .accessibilityLabel("New Folder")
            }
        }
    }
}
