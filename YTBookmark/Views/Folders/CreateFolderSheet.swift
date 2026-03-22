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
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .onChange(of: name) { _, new in
                            if new.count > 30 { name = String(new.prefix(30)) }
                        }
                } header: {
                    Text("Folder Name")
                } footer: {
                    if !name.isEmpty {
                        Text("\(name.count)/30")
                            .font(.caption)
                            .foregroundStyle(name.count > 25 ? Color.red : Color.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
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
