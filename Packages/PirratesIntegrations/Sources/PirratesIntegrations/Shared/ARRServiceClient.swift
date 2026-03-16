import Foundation
import PirratesCore

struct ARRServiceClient: Sendable {
    let profile: ServerProfile
    let apiKey: String
    let httpClient: HTTPClient
    let decoder: JSONDecoder

    init(
        profile: ServerProfile,
        apiKey: String,
        httpClient: HTTPClient = URLSession.shared,
        decoder: JSONDecoder = ARRServiceClient.makeDecoder()
    ) {
        self.profile = profile
        self.apiKey = apiKey
        self.httpClient = httpClient
        self.decoder = decoder
    }

    func send<T: Decodable>(_ request: APIRequest, as type: T.Type) async throws -> T {
        let urlRequest = try RequestBuilder.makeURLRequest(for: profile, apiKey: apiKey, request: request)
        let (data, response) = try await httpClient.data(for: urlRequest)
        try ResponseValidator.validate(response)
        return try decoder.decode(T.self, from: data)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = Self.parseDate(value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date format: \(value)"
            )
        }
        return decoder
    }

    private static func parseDate(_ value: String) -> Date? {
        let fractionalSecondsFormatter = ISO8601DateFormatter()
        fractionalSecondsFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalSecondsFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
