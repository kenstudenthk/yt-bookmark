import XCTest
@testable import YTBookmark

final class BilibiliURLParserTests: XCTestCase {

    // MARK: - Valid URLs

    func test_standard_noTimestamp_returnsZero() {
        let result = BilibiliURLParser.parse("https://www.bilibili.com/video/BV1xx411c7mD")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_standard_withTimestamp_parsesCorrectly() {
        let result = BilibiliURLParser.parse("https://www.bilibili.com/video/BV1xx411c7mD?t=123")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 123)
    }

    func test_mobile_noWWW_parsesCorrectly() {
        let result = BilibiliURLParser.parse("https://m.bilibili.com/video/BV1xx411c7mD")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_noSubdomain_parsesCorrectly() {
        let result = BilibiliURLParser.parse("https://bilibili.com/video/BV1xx411c7mD")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_timestampAmidExtraParams_parsesCorrectly() {
        let result = BilibiliURLParser.parse(
            "https://www.bilibili.com/video/BV1xx411c7mD?share_source=copy_web&vd_source=abc&t=456"
        )
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 456)
    }

    func test_trailingSlash_parsesCorrectly() {
        let result = BilibiliURLParser.parse("https://www.bilibili.com/video/BV1xx411c7mD/")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_timestampZero_returnsZero() {
        let result = BilibiliURLParser.parse("https://www.bilibili.com/video/BV1xx411c7mD?t=0")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    // MARK: - Invalid timestamp falls back to 0

    func test_invalidTimestamp_returnsZero() {
        let result = BilibiliURLParser.parse("https://www.bilibili.com/video/BV1xx411c7mD?t=abc")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_negativeTimestamp_returnsZero() {
        let result = BilibiliURLParser.parse("https://www.bilibili.com/video/BV1xx411c7mD?t=-5")
        XCTAssertEqual(result?.videoID, "BV1xx411c7mD")
        XCTAssertEqual(result?.timestamp, 0)
    }

    // MARK: - Nil cases

    func test_shortURL_b23tv_returnsNil() {
        // b23.tv requires redirect resolution — not handled by parser
        XCTAssertNil(BilibiliURLParser.parse("https://b23.tv/UXCLMx2"))
    }

    func test_youtubeURL_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
    }

    func test_bilibiliRootOnly_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse("https://www.bilibili.com/"))
    }

    func test_bilibiliNoVideoPath_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse("https://www.bilibili.com/bangumi/play/ss123"))
    }

    func test_invalidBVID_tooShort_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse("https://www.bilibili.com/video/BV123"))
    }

    func test_invalidBVID_noPrefix_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse("https://www.bilibili.com/video/1xx411c7mD12"))
    }

    func test_avNumberFormat_returnsNil() {
        // av numbers (old format) are out of scope in v1
        XCTAssertNil(BilibiliURLParser.parse("https://www.bilibili.com/video/av123456"))
    }

    func test_emptyString_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse(""))
    }

    func test_nonURL_returnsNil() {
        XCTAssertNil(BilibiliURLParser.parse("not a url at all"))
    }
}
