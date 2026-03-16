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

    func queue(pageSize: Int = 10) async throws -> [RadarrQueueRecordDTO] {
        let response = try await client.send(
            APIRequest(
                path: "/api/v3/queue",
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "pageSize", value: String(pageSize)),
                ]
            ),
            as: RadarrQueuePageDTO.self
        )

        return response.records ?? []
    }

    func history(pageSize: Int = 10) async throws -> [RadarrHistoryRecordDTO] {
        let response = try await client.send(
            APIRequest(
                path: "/api/v3/history",
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "pageSize", value: String(pageSize)),
                    URLQueryItem(name: "sortKey", value: "date"),
                    URLQueryItem(name: "sortDirection", value: "descending"),
                ]
            ),
            as: RadarrHistoryPageDTO.self
        )

        return response.records ?? []
    }

    public func search(term: String) async throws -> [SearchResult] {
        let results = try await client.send(
            APIRequest(
                path: "/api/v3/movie/lookup",
                queryItems: [URLQueryItem(name: "term", value: term)]
            ),
            as: [RadarrMovieDTO].self
        )

        return results.compactMap { RadarrMovieMapper.map($0, profile: profile) }
    }

    public func calendar(start: Date, end: Date) async throws -> [RadarrCalendarDTO] {
        try await client.send(
            APIRequest(
                path: "/api/v3/calendar",
                queryItems: [
                    URLQueryItem(name: "start", value: Self.calendarDateString(from: start)),
                    URLQueryItem(name: "end", value: Self.calendarDateString(from: end)),
                ]
            ),
            as: [RadarrCalendarDTO].self
        )
    }

    private static func calendarDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func qualityProfiles() async throws -> [QualityProfileDTO] {
        try await client.send(APIRequest(path: "/api/v3/qualityprofile"), as: [QualityProfileDTO].self)
    }

    func rootFolders() async throws -> [RootFolderDTO] {
        try await client.send(APIRequest(path: "/api/v3/rootfolder"), as: [RootFolderDTO].self)
    }

    public func addMovie(
        tmdbID: Int,
        rootFolderPath: String,
        monitor: String,
        qualityProfileID: Int,
        minimumAvailability: String,
        searchForMovie: Bool
    ) async throws {
        let payload = RadarrAddMoviePayload(
            tmdbId: tmdbID,
            rootFolderPath: rootFolderPath,
            monitor: monitor,
            qualityProfileId: qualityProfileID,
            minimumAvailability: minimumAvailability,
            addOptions: .init(searchForMovie: searchForMovie, addMethod: "manual")
        )

        _ = try await client.send(APIRequest(path: "/api/v3/movie", method: "POST", body: try JSONEncoder().encode(payload)), as: RadarrMovieDTO.self)
    }

    func library() async throws -> [RadarrMovieDTO] {
        try await client.send(APIRequest(path: "/api/v3/movie"), as: [RadarrMovieDTO].self)
    }
}

private struct RadarrAddMoviePayload: Encodable {
    let tmdbId: Int
    let rootFolderPath: String
    let monitor: String
    let qualityProfileId: Int
    let minimumAvailability: String
    let addOptions: RadarrAddMovieOptionsPayload
}

private struct RadarrAddMovieOptionsPayload: Encodable {
    let searchForMovie: Bool
    let addMethod: String
}
