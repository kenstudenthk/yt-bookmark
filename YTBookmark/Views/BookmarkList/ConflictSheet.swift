import SwiftUI

struct ConflictSheet: View {
    @Environment(ConflictStore.self) private var conflictStore
    @State private var rememberChoice = false
    @State private var errorMessage: String?

    var body: some View {
        if let conflict = conflictStore.pendingConflict {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Existing record info
                        VStack(alignment: .leading, spacing: 8) {
                            Label("已保存的版本", systemImage: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(conflict.existing.title)
                                .font(.headline)
                            HStack {
                                Text("时间戳: \(formatTimestamp(conflict.existing.lastTimestamp))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(conflict.existing.savedAt.formatted(.relative(presentation: .named)))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            if !conflict.existing.note.isEmpty {
                                Text(conflict.existing.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        // Incoming info
                        VStack(alignment: .leading, spacing: 8) {
                            Label("新的分享", systemImage: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("时间戳: \(formatTimestamp(conflict.incoming.timestamp))")
                                .font(.headline)
                            if !conflict.incoming.note.isEmpty {
                                Text(conflict.incoming.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                        Toggle("记住我的选择（此视频）", isOn: $rememberChoice)
                            .font(.subheadline)
                            .padding(.horizontal, 4)

                        if let err = errorMessage {
                            Label(err, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        VStack(spacing: 12) {
                            Button {
                                resolve(choice: .cover, conflict: conflict)
                            } label: {
                                Label("覆盖原记录", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)

                            Button {
                                resolve(choice: .addNew, conflict: conflict)
                            } label: {
                                Label("新增记录", systemImage: "plus.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("取消", role: .cancel) {
                                conflictStore.dismiss()
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
                .navigationTitle("视频已存在")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func formatTimestamp(_ seconds: Int) -> String {
        if seconds == 0 { return "开头" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    private func resolve(choice: SavingMethod, conflict: DuplicateConflict) {
        do {
            let methodToRemember: SavingMethod? = rememberChoice ? choice : nil
            switch choice {
            case .cover:
                try conflictStore.resolveCover(rememberAs: methodToRemember)
            case .addNew, .ask:
                try conflictStore.resolveAddNew(rememberAs: methodToRemember)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
