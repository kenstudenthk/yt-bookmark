import SwiftUI
import SwiftData

struct MoveFolderSheet: View {

    let record: VideoRecord

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \Folder.createdAt, order: .forward)
    private var folders: [Folder]

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        move(to: nil)
                    } label: {
                        HStack {
                            Image(systemName: "tray")
                                .foregroundStyle(.secondary)
                            Text("Uncategorised")
                                .foregroundStyle(.primary)
                            Spacer()
                            if record.folder == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                if !folders.isEmpty {
                    Section("Folders") {
                        ForEach(folders) { folder in
                            Button {
                                move(to: folder)
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: folder.colorHex))
                                        .frame(width: 12, height: 12)
                                    Text(folder.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if record.folder?.id == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func move(to folder: Folder?) {
        do {
            try BookmarkRepository(context: context).moveRecord(record, to: folder)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
