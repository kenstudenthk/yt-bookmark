import SwiftUI
import SwiftData
import UIKit

// MARK: - Navigation State

/// Centralised navigation state injected into the environment.
/// Both YTBookmarkApp (for deep links) and child views (for sheets/navigation) access this.
@Observable
final class NavigationStore {
    var path = NavigationPath()
    var activeSheet: ActiveSheet? = nil
}

// MARK: - Sheet Enum

enum ActiveSheet: Identifiable {
    case search
    case editNote(VideoRecord)
    case moveToFolder(VideoRecord)

    var id: String {
        switch self {
        case .search:                  "search"
        case .editNote(let r):         "editNote-\(r.id)"
        case .moveToFolder(let r):     "moveToFolder-\(r.id)"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {

    @Environment(PendingRecordService.self) private var pendingRecordService
    @Environment(NavigationStore.self)      private var navigationStore

    var body: some View {
        NavigationStack(path: Binding(
            get: { navigationStore.path },
            set: { navigationStore.path = $0 }
        )) {
            BookmarkListView()
        }
        .sheet(item: Binding(
            get: { navigationStore.activeSheet },
            set: { navigationStore.activeSheet = $0 }
        )) { sheet in
            sheetContent(for: sheet)
        }
        .overlay(alignment: .bottom) {
            if let message = pendingRecordService.toastMessage {
                ToastView(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: pendingRecordService.toastMessage)
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .search:
            // Phase 2D: SearchView()
            Text("Search — coming in Phase 2D")
        case .editNote(let record):
            EditNoteSheet(record: record)
        case .moveToFolder(let record):
            MoveFolderSheet(record: record)
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.black.opacity(0.8), in: Capsule())
            .onAppear {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
    }
}
