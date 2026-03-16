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
        decoder: JSONDecoder = JSONDecoder()
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
}
