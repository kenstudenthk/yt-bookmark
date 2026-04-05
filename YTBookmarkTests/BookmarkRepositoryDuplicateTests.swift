import XCTest
import SwiftData
@testable import YTBookmark

final class BookmarkRepositoryDuplicateTests: XCTestCase {
    var container: ModelContainer!
    var repository: BookmarkRepository!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: VideoRecord.self, Folder.self, BookmarkStamp.self,
            configurations: config
        )
        repository = BookmarkRepository(context: ModelContext(container))
    }

    override func tearDownWithError() throws {
        container = nil
        repository = nil
    }

    func test_findFirstRecord_returnsNilForUnknownVideoID() throws {
        let result = try repository.findFirstRecord(videoID: "unknown_abc")
        XCTAssertNil(result)
    }

    func test_findFirstRecord_returnsMatchingRecord() throws {
        _ = try repository.createRecord(
            videoID: "abc123", title: "Test",
            thumbnailURL: "", timestamp: 0, platform: "youtube"
        )
        let found = try repository.findFirstRecord(videoID: "abc123")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.videoID, "abc123")
    }

    func test_coverRecord_updatesTimestampAndNote() throws {
        let record = try repository.createRecord(
            videoID: "abc123", title: "Test",
            thumbnailURL: "", timestamp: 10, note: "old note", platform: "youtube"
        )
        try repository.coverRecord(record, timestamp: 999, note: "new note")
        XCTAssertEqual(record.lastTimestamp, 999)
        XCTAssertEqual(record.note, "new note")
        XCTAssertEqual(record.title, "Test") // unchanged
    }

    func test_coverRecord_doesNotChangeTitle() throws {
        let record = try repository.createRecord(
            videoID: "abc123", title: "Original Title",
            thumbnailURL: "http://thumb.jpg", timestamp: 0, platform: "youtube"
        )
        try repository.coverRecord(record, timestamp: 500, note: "")
        XCTAssertEqual(record.title, "Original Title")
        XCTAssertEqual(record.thumbnailURL, "http://thumb.jpg")
    }

    func test_fetchFolder_returnsNilForUnknownID() throws {
        let result = try repository.fetchFolder(byID: UUID())
        XCTAssertNil(result)
    }

    func test_fetchFolder_returnsExistingFolder() throws {
        let folder = try repository.createFolder(name: "Work", colorHex: "#FF0000")
        let found = try repository.fetchFolder(byID: folder.id)
        XCTAssertEqual(found?.id, folder.id)
    }

    func test_updateSavingMethod_persistsChange() throws {
        let record = try repository.createRecord(
            videoID: "abc123", title: "Test",
            thumbnailURL: "", timestamp: 0, platform: "youtube"
        )
        XCTAssertEqual(record.savingMethod, .ask)
        try repository.updateSavingMethod(on: record, method: .cover)
        XCTAssertEqual(record.savingMethod, .cover)
    }
}
