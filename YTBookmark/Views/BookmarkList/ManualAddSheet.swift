import SwiftUI

struct ManualAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(ConflictStore.self) private var conflictStore
    @State private var viewModel = ManualAddViewModel()

    private var repository: BookmarkRepository {
        BookmarkRepository(context: context)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("视频链接") {
                    TextField("粘贴 YouTube 或 Bilibili 链接", text: $viewModel.urlInput)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    TextField("添加备注（可选）", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("备注")
                }

                if case .error(let msg) = viewModel.state {
                    Section {
                        Label(msg, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("手动添加书签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if case .loading = viewModel.state {
                        ProgressView()
                    } else {
                        Button("保存") {
                            Task {
                                await viewModel.submit(
                                    repository: repository,
                                    conflictStore: conflictStore
                                )
                            }
                        }
                        .disabled(viewModel.urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .success = newState {
                    dismiss()
                }
            }
        }
    }
}
