import XCTest
@testable import YTBookmark

final class YouTubeURLParserTests: XCTestCase {

    // MARK: - Format 1: youtu.be + t= (integer seconds)

    func test_youtuBe_withTimestamp_parsesVideoIDAndTimestamp() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=101&si=abc123")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 101)
    }

    func test_youtuBe_withTimestamp_noSiParam_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=42")
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 42)
    }

    // MARK: - Format 2: youtu.be without t=

    func test_youtuBe_noTimestamp_returnsZeroTimestamp() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?si=abc123")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_youtuBe_noParams_returnsZeroTimestamp() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 0)
    }

    // MARK: - Format 3: youtube.com/watch + t= (integer seconds)

    func test_youtubeWatch_withTimestamp_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ&t=101")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 101)
    }

    func test_youtubeWatch_noTimestamp_returnsZeroTimestamp() {
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 0)
    }

    // MARK: - Format 4: youtube.com/watch + formatted time (XhYmZs)

    func test_youtubeWatch_formattedTime_fullHMS_parsesCorrectly() {
        // 1h33m30s = 3600 + 1980 + 30 = 5610
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ&t=1h33m30s")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 5610)
    }

    func test_youtubeWatch_formattedTime_minutesAndSeconds_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ&t=3m30s")
        XCTAssertEqual(result?.timestamp, 210) // 180 + 30
    }

    func test_youtubeWatch_formattedTime_secondsOnly_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ&t=30s")
        XCTAssertEqual(result?.timestamp, 30)
    }

    func test_youtubeWatch_formattedTime_hoursOnly_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ&t=1h")
        XCTAssertEqual(result?.timestamp, 3600)
    }

    func test_youtubeWatch_formattedTime_hoursAndMinutes_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtube.com/watch?v=dQw4w9WgXcQ&t=2h15m")
        XCTAssertEqual(result?.timestamp, 8100) // 7200 + 900
    }

    // MARK: - www. prefix support

    func test_wwwYoutubeCom_watch_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=60")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "dQw4w9WgXcQ")
        XCTAssertEqual(result?.timestamp, 60)
    }

    func test_wwwYoutuBe_parsesCorrectly() {
        // youtu.be never has www, but ensure host matching is exact
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=5")
        XCTAssertEqual(result?.timestamp, 5)
    }

    // MARK: - si= parameter stripped (ignored)

    func test_siParam_isIgnored_doesNotAffectParse() {
        let withSi    = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=10&si=TRACKING")
        let withoutSi = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=10")
        XCTAssertEqual(withSi?.videoID, withoutSi?.videoID)
        XCTAssertEqual(withSi?.timestamp, withoutSi?.timestamp)
    }

    // MARK: - Invalid t= values → timestamp = 0

    func test_invalidTimestamp_alphabetic_returnsZero() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=abc")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_invalidTimestamp_float_returnsZero() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=1.5")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timestamp, 0)
    }

    func test_invalidTimestamp_emptyValue_returnsZero() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timestamp, 0)
    }

    // MARK: - videoID validation

    func test_invalidVideoID_tooShort_returnsNil() {
        let result = YouTubeURLParser.parse("https://youtu.be/short")
        XCTAssertNil(result)
    }

    func test_invalidVideoID_tooLong_returnsNil() {
        let result = YouTubeURLParser.parse("https://youtu.be/thisIsWayTooLong123")
        XCTAssertNil(result)
    }

    func test_invalidVideoID_illegalCharacters_returnsNil() {
        let result = YouTubeURLParser.parse("https://youtu.be/invalid!@#$%^&*(")
        XCTAssertNil(result)
    }

    func test_validVideoID_withUnderscoreAndHyphen_parsesCorrectly() {
        // Valid base64url characters; exactly 11 chars: a B _ d E f G - i J 1
        let result = YouTubeURLParser.parse("https://youtu.be/aB_dEfG-iJ1")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.videoID, "aB_dEfG-iJ1")
    }

    // MARK: - Non-YouTube URLs → nil

    func test_nonYoutubeURL_returnsNil() {
        XCTAssertNil(YouTubeURLParser.parse("https://vimeo.com/123456789"))
    }

    func test_randomURL_returnsNil() {
        XCTAssertNil(YouTubeURLParser.parse("https://example.com/watch?v=dQw4w9WgXcQ"))
    }

    func test_emptyString_returnsNil() {
        XCTAssertNil(YouTubeURLParser.parse(""))
    }

    func test_malformedURL_returnsNil() {
        XCTAssertNil(YouTubeURLParser.parse("not a url at all"))
    }

    // MARK: - YouTube Shorts → nil (out of scope v1)

    func test_youtubeShorts_returnsNil() {
        XCTAssertNil(YouTubeURLParser.parse("https://youtube.com/shorts/dQw4w9WgXcQ"))
    }

    func test_wwwYoutubeShorts_returnsNil() {
        XCTAssertNil(YouTubeURLParser.parse("https://www.youtube.com/shorts/dQw4w9WgXcQ"))
    }

    // MARK: - t=0 edge case

    func test_timestampZero_returnsZero() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=0")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timestamp, 0)
    }

    // MARK: - Large timestamp

    func test_largeTimestamp_parsesCorrectly() {
        let result = YouTubeURLParser.parse("https://youtu.be/dQw4w9WgXcQ?t=7261")
        XCTAssertEqual(result?.timestamp, 7261)
    }
}
