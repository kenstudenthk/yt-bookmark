import XCTest
@testable import YTBookmark

final class UserPreferencesTests: XCTestCase {
    let suite = UserDefaults(suiteName: "test.ytbookmark.userprefs")!

    override func setUp() {
        super.setUp()
        suite.removePersistentDomain(forName: "test.ytbookmark.userprefs")
    }

    func test_defaultFolderID_nilInitially() {
        XCTAssertNil(UserPreferences.defaultFolderID(in: suite))
    }

    func test_setAndGetDefaultFolderID() {
        let id = UUID()
        UserPreferences.setDefaultFolderID(id, in: suite)
        XCTAssertEqual(UserPreferences.defaultFolderID(in: suite), id)
    }

    func test_clearDefaultFolderID() {
        let id = UUID()
        UserPreferences.setDefaultFolderID(id, in: suite)
        UserPreferences.clearDefaultFolderID(in: suite)
        XCTAssertNil(UserPreferences.defaultFolderID(in: suite))
    }
}
