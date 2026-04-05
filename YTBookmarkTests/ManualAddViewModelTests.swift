import XCTest
import SwiftData
@testable import YTBookmark

final class ManualAddViewModelTests: XCTestCase {
    var container: ModelContainer!
    var repository: BookmarkRepository!
    var conflictStore: ConflictStore!
    var vm: ManualAddViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: VideoRecord.self, Folder.self, BookmarkStamp.self,
            configurations: config
        )
        repository = BookmarkRepository(context: ModelContext(container))
        conflictStore = ConflictStore(repository: repository)
        vm = ManualAddViewModel()
    }

    override func tearDownWithError() throws {
        vm = nil
        conflictStore = nil
        repository = nil
        container = nil
    }

    func test_emptyURL_setsErrorState() async {
        vm.urlInput = ""
        await vm.submit(repository: repository, conflictStore: conflictStore)
        if case .error = vm.state { /* pass */ } else {
            XCTFail("Expected error, got \(vm.state)")
        }
    }

    func test_invalidURL_setsErrorState() async {
        vm.urlInput = "not a valid url at all !!!"
        await vm.submit(repository: repository, conflictStore: conflictStore)
        if case .error = vm.state { /* pass */ } else {
            XCTFail("Expected error, got \(vm.state)")
        }
    }

    func test_nonVideoURL_setsErrorState() async {
        vm.urlInput = "https://example.com/some/random/page"
        await vm.submit(repository: repository, conflictStore: conflictStore)
        if case .error = vm.state { /* pass */ } else {
            XCTFail("Expected error, got \(vm.state)")
        }
    }
}
