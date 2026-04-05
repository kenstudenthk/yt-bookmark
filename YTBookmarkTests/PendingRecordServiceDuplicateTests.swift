// PendingRecordServiceDuplicateTests.swift
//
// NOTE: PendingRecordService.ingestPendingRecord() is tightly coupled to
// async network calls (YouTubeAPIService / BilibiliAPIService), making it
// impractical to unit-test the routing logic by invoking the service directly
// without a network mocking layer.
//
// These tests instead exercise the three routing outcomes — cover, addNew,
// ask — by reproducing the exact repository and ConflictStore calls that
// PendingRecordService makes in each branch. This validates the correctness
// of the operations the service delegates to, without racing against real
// network I/O.

import XCTest
import SwiftData
@testable import YTBookmark

final class PendingRecordServiceDuplicateTests: XCTestCase {

    var container: ModelContainer!
    var repository: BookmarkRepository!
    var conflictStore: ConflictStore!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: VideoRecord.self, Folder.self, BookmarkStamp.self,
            configurations: config
        )
        repository = BookmarkRepository(context: ModelContext(container))
        conflictStore = ConflictStore(repository: repository)
    }

    override func tearDownWithError() throws {
        conflictStore = nil
        repository = nil
        container = nil
    }

    // MARK: - Helpers

    /// Simulates the metadata resolved after the API fetch.
    private func makeMetadata() -> (title: String, thumbnailURL: String, needsEnrich: Bool) {
        ("Test Video", "https://img.example.com/thumb.jpg", false)
    }

    /// Creates a pre-existing VideoRecord with the given savingMethod.
    @discardableResult
    private func seedExisting(videoID: String, savingMethod: SavingMethod) throws -> VideoRecord {
        let record = try repository.createRecord(
            videoID: videoID, title: "Existing Title",
            thumbnailURL: "", timestamp: 0, platform: "youtube"
        )
        try repository.updateSavingMethod(on: record, method: savingMethod)
        return record
    }

    // MARK: - Outcome 1: No duplicate — createRecord is called, widget data refreshable

    func test_noDuplicate_createsNewRecord() throws {
        // Precondition: no existing record
        XCTAssertNil(try repository.findFirstRecord(videoID: "vid-new"))

        let (title, thumbnailURL, needsEnrich) = makeMetadata()
        let defaultFolder: Folder? = nil

        _ = try repository.createRecord(
            videoID: "vid-new",
            title: title,
            thumbnailURL: thumbnailURL,
            timestamp: 42,
            note: "my note",
            needsEnrichment: needsEnrich,
            folder: defaultFolder,
            platform: "youtube"
        )

        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.videoID, "vid-new")
        XCTAssertEqual(all.first?.lastTimestamp, 42)
    }

    func test_noDuplicate_defaultFolderIsApplied() throws {
        let folder = try repository.createFolder(name: "Watch Later", colorHex: "#FF0000")
        UserPreferences.setDefaultFolderID(folder.id)
        defer { UserPreferences.clearDefaultFolderID() }

        let defaultFolder = UserPreferences.defaultFolderID()
            .flatMap { try? repository.fetchFolder(byID: $0) }

        _ = try repository.createRecord(
            videoID: "vid-folder",
            title: "Titled",
            thumbnailURL: "",
            timestamp: 0,
            needsEnrichment: false,
            folder: defaultFolder,
            platform: "youtube"
        )

        let record = try repository.findFirstRecord(videoID: "vid-folder")
        XCTAssertNotNil(record?.folder)
        XCTAssertEqual(record?.folder?.id, folder.id)
    }

    // MARK: - Outcome 2: Duplicate with .cover — coverRecord updates, no new record

    func test_duplicateCover_updatesExistingTimestampAndNote() throws {
        let existing = try seedExisting(videoID: "vid-cover", savingMethod: .cover)

        // Simulate the .cover branch
        try repository.coverRecord(existing, timestamp: 999, note: "updated note")

        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 1, "Cover must not create a new record")
        XCTAssertEqual(existing.lastTimestamp, 999)
        XCTAssertEqual(existing.note, "updated note")
    }

    func test_duplicateCover_doesNotCreateNewRecord() throws {
        let existing = try seedExisting(videoID: "vid-cover2", savingMethod: .cover)

        try repository.coverRecord(existing, timestamp: 100, note: "")

        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - Outcome 3: Duplicate with .addNew — createRecord adds second record

    func test_duplicateAddNew_createsAdditionalRecord() throws {
        try seedExisting(videoID: "vid-addnew", savingMethod: .addNew)
        let (title, thumbnailURL, needsEnrich) = makeMetadata()

        _ = try repository.createRecord(
            videoID: "vid-addnew",
            title: title,
            thumbnailURL: thumbnailURL,
            timestamp: 55,
            note: "new note",
            needsEnrichment: needsEnrich,
            folder: nil,
            platform: "youtube"
        )

        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 2, "addNew must create a second record for the same videoID")
    }

    func test_duplicateAddNew_existingRecordUnchanged() throws {
        let existing = try seedExisting(videoID: "vid-addnew2", savingMethod: .addNew)
        let originalTimestamp = existing.lastTimestamp

        _ = try repository.createRecord(
            videoID: "vid-addnew2",
            title: "New Record",
            thumbnailURL: "",
            timestamp: 77,
            needsEnrichment: false,
            folder: nil,
            platform: "youtube"
        )

        XCTAssertEqual(existing.lastTimestamp, originalTimestamp, "Existing record must not be mutated by addNew")
    }

    // MARK: - Outcome 4: Duplicate with .ask + conflictStore — conflict is raised, no new record

    func test_duplicateAsk_withConflictStore_raisesConflict() throws {
        let existing = try seedExisting(videoID: "vid-ask", savingMethod: .ask)
        let (title, thumbnailURL, needsEnrich) = makeMetadata()
        let defaultFolder: Folder? = nil

        let incoming = IncomingBookmark(
            videoID: "vid-ask",
            title: title,
            thumbnailURL: thumbnailURL,
            timestamp: 30,
            note: "ask note",
            needsEnrichment: needsEnrich,
            platform: "youtube",
            folder: defaultFolder
        )
        conflictStore.raise(DuplicateConflict(incoming: incoming, existing: existing))

        XCTAssertNotNil(conflictStore.pendingConflict)
        XCTAssertEqual(conflictStore.pendingConflict?.incoming.videoID, "vid-ask")
        XCTAssertEqual(conflictStore.pendingConflict?.incoming.timestamp, 30)
    }

    func test_duplicateAsk_withConflictStore_doesNotCreateNewRecord() throws {
        let existing = try seedExisting(videoID: "vid-ask2", savingMethod: .ask)
        let incoming = IncomingBookmark(
            videoID: "vid-ask2",
            title: "Title",
            thumbnailURL: "",
            timestamp: 10,
            note: "",
            needsEnrichment: false,
            platform: "youtube",
            folder: nil
        )

        // Service raises conflict and returns without saving
        conflictStore.raise(DuplicateConflict(incoming: incoming, existing: existing))

        let all = try repository.fetchAllRecords()
        XCTAssertEqual(all.count, 1, "No new record should be created when conflict is raised for .ask")
        // Existing record is also not modified
        XCTAssertEqual(existing.lastTimestamp, 0)
    }

    func test_duplicateAsk_withConflictStore_incomingCarriesDefaultFolder() throws {
        let folder = try repository.createFolder(name: "Queue", colorHex: "#00FF00")
        UserPreferences.setDefaultFolderID(folder.id)
        defer { UserPreferences.clearDefaultFolderID() }

        let existing = try seedExisting(videoID: "vid-ask3", savingMethod: .ask)
        let defaultFolder = UserPreferences.defaultFolderID()
            .flatMap { try? repository.fetchFolder(byID: $0) }

        let incoming = IncomingBookmark(
            videoID: "vid-ask3",
            title: "T",
            thumbnailURL: "",
            timestamp: 0,
            note: "",
            needsEnrichment: false,
            platform: "youtube",
            folder: defaultFolder
        )
        conflictStore.raise(DuplicateConflict(incoming: incoming, existing: existing))

        XCTAssertEqual(
            conflictStore.pendingConflict?.incoming.folder?.id, folder.id,
            "Default folder must be forwarded into IncomingBookmark for conflict sheet to display"
        )
    }
}
