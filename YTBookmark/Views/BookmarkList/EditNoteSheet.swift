import SwiftUI
import SwiftData

struct EditNoteSheet: View {

    let record: VideoRecord

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var note = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Add a note…", text: $note, axis: .vertical)
                        .lineLimit(5...10)
                        .onChange(of: note) { _, new in
                            if new.count > 500 { note = String(new.prefix(500)) }
                        }
                } footer: {
                    Text("\(note.count)/500")
                        .font(.caption)
                        .foregroundStyle(noteCountColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
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
        .onAppear { note = record.note }
    }

    private var noteCountColor: Color {
        if note.count > 490 { return .red }
        if note.count > 400 { return .orange }
        return .secondary
    }

    private func save() {
        do {
            try BookmarkRepository(context: context).updateNote(on: record, note: note)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
