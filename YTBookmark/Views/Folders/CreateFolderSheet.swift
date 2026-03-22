import SwiftUI
import SwiftData

struct CreateFolderSheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    var onCreate: (String, String) -> Void

    @State private var name = ""
    @State private var selectedColor = Folder.presetColors[0]

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                }

                Section("Colour") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Folder.presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if hex == selectedColor {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColor = hex }
                                .accessibilityLabel("Colour \(hex)")
                                .accessibilityAddTraits(hex == selectedColor ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onCreate(name.trimmingCharacters(in: .whitespaces), selectedColor)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
