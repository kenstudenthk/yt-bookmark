import SwiftUI
import SwiftData

@main
struct YTBookmarkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [VideoRecord.self, Folder.self, BookmarkStamp.self])
    }
}
