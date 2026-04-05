import SwiftUI
import SwiftData
import Observation

@Observable
final class FolderListViewModel {

    var errorMessage: String?
    var isShowingCreateSheet = false

    // MARK: - Actions

    func createFolder(name: String, colorHex: String, context: ModelContext) {
        do {
            try BookmarkRepository(context: context).createFolder(name: name, colorHex: colorHex)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFolder(_ folder: Folder, context: ModelContext) {
        do {
            try BookmarkRepository(context: context).deleteFolder(folder)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Default Folder

    func setAsDefault(folder: Folder) {
        UserPreferences.setDefaultFolderID(folder.id)
    }

    func clearDefault() {
        UserPreferences.clearDefaultFolderID()
    }

    var defaultFolderID: UUID? {
        UserPreferences.defaultFolderID()
    }
}
