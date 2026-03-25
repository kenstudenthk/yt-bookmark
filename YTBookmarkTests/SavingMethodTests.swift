import XCTest
@testable import YTBookmark

final class SavingMethodTests: XCTestCase {
    func test_rawValue_roundTrip() {
        XCTAssertEqual(SavingMethod(rawValue: "ask"), .ask)
        XCTAssertEqual(SavingMethod(rawValue: "cover"), .cover)
        XCTAssertEqual(SavingMethod(rawValue: "addNew"), .addNew)
        XCTAssertNil(SavingMethod(rawValue: "unknown"))
    }
    func test_defaultIsAsk() {
        XCTAssertEqual(SavingMethod.ask.rawValue, "ask")
    }
}
