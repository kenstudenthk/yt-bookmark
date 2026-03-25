import XCTest
import SwiftData
@testable import YTBookmark

final class ConflictStoreTests: XCTestCase {
    var container: ModelContainer!
    var repository: BookmarkRepository!
    var store: ConflictStore!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: VideoRecord.self, Folder.self, BookmarkStamp.self,
            configurations: config
        )
        repository = BookmarkRepository(context: ModelContext(container))
        store = ConflictStore(repository: repository)
    }

    override func tearDownWithError() throws {
        store = nil
        repository = nil
        container = nil
    }

    func test_initialState_noPendingConflict() {
        XCTAssertNil(store.pendingConflict)
        XCTAssertNil(store.errorMessage)
    }

    func makeConflict(videoID: String = "abc") throws -> DuplicateConflict {
        let existing = try repository.createRecord(
            videoID: videoID, title: "Old Title",
            thumbnailURL: "", timestamp: 0, platform: "youtube"
        )
        let incoming = IncomingBookmark(
            videoID: videoID, title: "Old Title", thumbnailURL: "",
            timestamp: 99, note: "note", needsEnrichment: false,
            platform: "youtube", folder: nil
        )
        return DuplicateConflict(incoming: incoming, existing: existing)
    }

    func test_raise_setsPendingConflict() throws {
        let conflict = try makeConflict()
        store.raise(conflict)
        XCTAssertNotNil(store.pendingConflict)
    }

    func test_dismiss_clearsPendingConflict() throws {
        let conflict = try makeConflict()
        store.raise(conflict)
        store.dismiss()
        XCTAssertNil(store.pendingConflict)
    }

    func test_resolveCover_updatesExistingRecord() throws {
        let conflict = try makeConflict()
        store.raise(conflict)
        try store.resolveCover()
        XCTAssertNil(store.pendingConflict)
        XCTAssertEqual(conflict.existing.lastTimestamp, 99)
        XCTAssertEqual(conflict.existing.note, "note")
    }

    func test_resolveCover_doesNotCreateNewRecord() throws {
        let conflict = try makeConflict()
        store.raise(conflict)
        try store.resolveCover()
        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 1)
    }

    func test_resolveAddNew_createsNewRecord() throws {
        let conflict = try makeConflict()
        store.raise(conflict)
        try store.resolveAddNew()
        XCTAssertNil(store.pendingConflict)
        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 2)
    }

    func test_resolveAddNew_preservesExistingRecord() throws {
        let conflict = try makeConflict()
        let originalTimestamp = conflict.existing.lastTimestamp
        store.raise(conflict)
        try store.resolveAddNew()
        XCTAssertEqual(conflict.existing.lastTimestamp, originalTimestamp)
    }
}
