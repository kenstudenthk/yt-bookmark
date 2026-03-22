import XCTest
@testable import YTBookmark

final class YouTubeAPIServiceTests: XCTestCase {

    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Success

    func test_fetchMetadata_successResponse_returnsTitle() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Self.successResponseData())
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertEqual(result?.title, "Never Gonna Give You Up")
    }

    func test_fetchMetadata_successResponse_returnsThumbnailURL() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Self.successResponseData())
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertEqual(result?.thumbnailURL, "https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg")
    }

    func test_fetchMetadata_successResponse_prefersMediumThumbnail() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Self.successResponseData(mediumURL: "https://medium.jpg", highURL: "https://high.jpg"))
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertEqual(result?.thumbnailURL, "https://medium.jpg")
    }

    func test_fetchMetadata_noMediumThumbnail_usesHighThumbnail() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Self.successResponseData(mediumURL: nil, highURL: "https://high.jpg"))
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertEqual(result?.thumbnailURL, "https://high.jpg")
    }

    // MARK: - Network error fallback

    func test_fetchMetadata_networkError_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    func test_fetchMetadata_timeout_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    // MARK: - HTTP error fallbacks

    func test_fetchMetadata_403quotaExceeded_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            (.status(403), Data())
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    func test_fetchMetadata_500serverError_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            (.status(500), Data())
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    func test_fetchMetadata_401unauthorized_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            (.status(401), Data())
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    // MARK: - Empty items fallback

    func test_fetchMetadata_emptyItemsArray_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Self.emptyItemsResponseData())
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    func test_fetchMetadata_malformedJSON_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Data("not json".utf8))
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    func test_fetchMetadata_emptyTitle_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            (.ok(), Self.successResponseData(title: ""))
        }
        let result = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNil(result)
    }

    // MARK: - Request structure

    func test_fetchMetadata_requestContainsVideoID() async {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (.ok(), Self.successResponseData())
        }
        _ = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertNotNil(capturedURL)
        XCTAssertTrue(capturedURL?.absoluteString.contains("id=dQw4w9WgXcQ") == true)
    }

    func test_fetchMetadata_requestContainsPartSnippet() async {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (.ok(), Self.successResponseData())
        }
        _ = await YouTubeAPIService.fetchMetadata(videoID: "dQw4w9WgXcQ", session: session)
        XCTAssertTrue(capturedURL?.absoluteString.contains("part=snippet") == true)
    }
}

// MARK: - Fixture helpers

private extension YouTubeAPIServiceTests {

    static func successResponseData(
        title: String = "Never Gonna Give You Up",
        mediumURL: String? = "https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg",
        highURL: String? = nil
    ) -> Data {
        var mediumJSON = "null"
        if let url = mediumURL {
            mediumJSON = #"{"url":"\#(url)","width":320,"height":180}"#
        }
        var highJSON = "null"
        if let url = highURL {
            highJSON = #"{"url":"\#(url)","width":480,"height":360}"#
        }
        let json = """
        {
          "items": [{
            "snippet": {
              "title": "\(title)",
              "thumbnails": {
                "medium": \(mediumJSON),
                "high": \(highJSON)
              }
            }
          }]
        }
        """
        return Data(json.utf8)
    }

    static func emptyItemsResponseData() -> Data {
        Data(#"{"items":[]}"#.utf8)
    }
}

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - HTTPURLResponse convenience

private extension HTTPURLResponse {
    static func ok(url: URL = URL(string: "https://googleapis.com")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    static func status(_ code: Int, url: URL = URL(string: "https://googleapis.com")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
    }
}
