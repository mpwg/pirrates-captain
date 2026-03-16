import Foundation
import PirratesCore

public struct RadarrClient: Sendable {
    public let profile: ServerProfile
    private let client: ARRServiceClient

    public init(
        profile: ServerProfile,
        apiKey: String,
        httpClient: HTTPClient = URLSession.shared
    ) {
        self.profile = profile
        self.client = ARRServiceClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
    }

    public func validateConnection() async throws -> RadarrSystemStatusDTO {
        try await client.send(APIRequest(path: "/api/v3/system/status"), as: RadarrSystemStatusDTO.self)
    }

    public func queueCount() async throws -> Int {
        let response = try await client.send(
            APIRequest(
                path: "/api/v3/queue",
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "pageSize", value: "1"),
                ]
            ),
            as: QueuePageDTO.self
        )

        return response.totalRecords ?? response.records?.count ?? 0
    }

    public func search(term: String) async throws -> [SearchResult] {
        let results = try await client.send(
            APIRequest(
                path: "/api/v3/movie/lookup",
                queryItems: [URLQueryItem(name: "term", value: term)]
            ),
            as: [RadarrMovieDTO].self
        )

        return results.map(RadarrMovieMapper.map)
    }
}
