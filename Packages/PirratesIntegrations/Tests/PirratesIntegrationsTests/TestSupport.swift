import Foundation
import PirratesCore

struct MockHTTPClient: HTTPClient {
    let handler: @Sendable (URLRequest) throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}

func makeJSONResponse(
    statusCode: Int,
    body: String,
    url: URL = URL(string: "https://example.com")!
) -> (Data, URLResponse) {
    let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    return (Data(body.utf8), response)
}
