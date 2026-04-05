import SwiftUI
import SwiftData

@main
struct YTBookmarkApp: App {

    private let container: ModelContainer
    private let repository: BookmarkRepository

    @State private var pendingRecordService: PendingRecordService
    @State private var navigationStore = NavigationStore()
    @State private var conflictStore: ConflictStore
    @State private var hasCompletedOnboarding =
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    @Environment(\.scenePhase) private var scenePhase

    init() {
        let c = try! ModelContainer(for: VideoRecord.self, Folder.self, BookmarkStamp.self)
        container  = c
        let repo   = BookmarkRepository(context: c.mainContext)
        repository = repo
        let store = ConflictStore(repository: repo)
        _conflictStore = State(wrappedValue: store)
        let svc = PendingRecordService(repository: repo)
        svc.conflictStore = store
        _pendingRecordService = State(wrappedValue: svc)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pendingRecordService)
                .environment(navigationStore)
                .environment(conflictStore)
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
        guard let (videoID, timestamp, platform) = DeepLinkService.parseIncomingDeepLink(url) else { return }

        // Reset navigation to root, dismiss any open sheet
        navigationStore.path        = NavigationPath()
        navigationStore.activeSheet = nil

        // Open video on the correct platform
        DeepLinkService.openVideo(videoID: videoID, timestamp: timestamp, platform: platform)
    }
}
