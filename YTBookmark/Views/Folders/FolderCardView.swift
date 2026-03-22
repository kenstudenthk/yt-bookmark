import SwiftUI

struct FolderCardView: View {

    let folder: Folder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(folder.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text(countLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .background(Color(hex: folder.colorHex).opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: folder.colorHex).opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(folder.name), \(countLabel)")
    }

    private var countLabel: String {
        let n = folder.records.count
        return n == 1 ? "1 bookmark" : "\(n) bookmarks"
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
