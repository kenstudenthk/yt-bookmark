import SwiftUI

struct ShareView: View {

    @Bindable var viewModel: ShareViewModel
    let context: NSExtensionContext

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    loadingView
                case .invalid(let message):
                    invalidView(message: message)
                case .ready(let parsed):
                    readyView(parsed: parsed)
                case .saving:
                    savingView
                }
            }
            .navigationTitle("YT Bookmark")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Existing pending record warning
        .alert("Replace Saved Bookmark?", isPresented: $viewModel.showPendingRecordWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive) {
                viewModel.confirmOverwriteAndSave(context: context)
            }
        } message: {
            Text("A bookmark is already waiting to be saved. Continuing will replace it.")
        }
        // App Group write failure
        .alert("Save Failed", isPresented: $viewModel.showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.saveErrorMessage)
        }
    }

    // MARK: - Sub-views

    private var loadingView: some View {
        ProgressView("Loading…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var savingView: some View {
        ProgressView("Saving…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func invalidView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Unsupported Link")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Close") {
                viewModel.cancel(context: context)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func readyView(parsed: ParsedVideoURL) -> some View {
        Form {
            // Video info section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(parsed.platform == "bilibili" ? Color.orange : Color.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(parsed.videoID)
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            TimestampBadge(seconds: parsed.timestamp)
                            Text(parsed.platform == "bilibili" ? "Bilibili" : "YouTube")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Video")
            } footer: {
                Text("Title will appear after opening the app.")
                    .font(.caption)
            }

            // Note section
            Section {
                TextField("Add a note (optional)", text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: viewModel.note) {
                        if viewModel.note.count > 500 {
                            viewModel.note = String(viewModel.note.prefix(500))
                        }
                    }
            } header: {
                Text("Note")
            } footer: {
                if viewModel.note.count > 450 {
                    Text("\(viewModel.note.count)/500")
                        .foregroundStyle(viewModel.note.count >= 500 ? .red : .secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancel(context: context)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.requestSave(context: context)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Timestamp Badge

struct TimestampBadge: View {
    let seconds: Int

    var body: some View {
        Text(label)
            .font(.caption.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(seconds == 0 ? Color.secondary : Color.red, in: Capsule())
    }

    private var label: String {
        if seconds == 0 { return "Start" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}
