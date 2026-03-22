import SwiftUI
import SwiftData

@main
struct YTBookmarkApp: App {

    private let container: ModelContainer
    private let repository: BookmarkRepository

    @State private var pendingRecordService: PendingRecordService
    @State private var navigationStore = NavigationStore()
    @State private var hasCompletedOnboarding =
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let c = try! ModelContainer(for: VideoRecord.self, Folder.self, BookmarkStamp.self)
        container  = c
        let repo   = BookmarkRepository(context: c.mainContext)
        repository = repo
        _pendingRecordService = State(
            wrappedValue: PendingRecordService(repository: repo)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pendingRecordService)
                .environment(navigationStore)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        hasCompletedOnboarding = true
                    }
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await pendingRecordService.ingestAndRetry() }
            }
        }
    }

    // MARK: - Deep Link

    private func handleDeepLink(_ url: URL) {
        guard let (videoID, timestamp) = DeepLinkService.parseIncomingDeepLink(url) else { return }

        // Reset navigation to root, dismiss any open sheet
        navigationStore.path         = NavigationPath()
        navigationStore.activeSheet  = nil

        // Open YouTube (primary: vnd.youtube://, fallback: Safari)
        DeepLinkService.openYouTube(videoID: videoID, timestamp: timestamp)
    }
}
