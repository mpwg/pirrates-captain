import Foundation
import PirratesCore

public struct SonarrClient: Sendable {
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

    public func validateConnection() async throws -> SonarrSystemStatusDTO {
        try await client.send(APIRequest(path: "/api/v3/system/status"), as: SonarrSystemStatusDTO.self)
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

    func queue(pageSize: Int = 10) async throws -> [SonarrQueueRecordDTO] {
        let response = try await client.send(
            APIRequest(
                path: "/api/v3/queue",
                queryItems: [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "pageSize", value: String(pageSize)),
                ]
            ),
            as: SonarrQueuePageDTO.self
        )

        return response.records ?? []
    }

    func history(pageSize: Int = 10) async throws -> [SonarrHistoryRecordDTO] {
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
            as: SonarrHistoryPageDTO.self
        )

        return response.records ?? []
    }

    public func search(term: String) async throws -> [SearchResult] {
        let results = try await client.send(
            APIRequest(
                path: "/api/v3/series/lookup",
                queryItems: [URLQueryItem(name: "term", value: term)]
            ),
            as: [SonarrSeriesDTO].self
        )

        return results.compactMap { SonarrSeriesMapper.map($0, profile: profile) }
    }

    public func calendar(start: Date, end: Date) async throws -> [SonarrCalendarDTO] {
        try await client.send(
            APIRequest(
                path: "/api/v3/calendar",
                queryItems: [
                    URLQueryItem(name: "start", value: Self.calendarDateString(from: start)),
                    URLQueryItem(name: "end", value: Self.calendarDateString(from: end)),
                ]
            ),
            as: [SonarrCalendarDTO].self
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

    public func addSeries(
        tvdbID: Int,
        rootFolderPath: String,
        monitor: String,
        qualityProfileID: Int,
        seriesType: String,
        seasonFolder: Bool,
        searchForMissingEpisodes: Bool,
        searchForCutoffUnmetEpisodes: Bool
    ) async throws {
        let payload = SonarrAddSeriesPayload(
            tvdbId: tvdbID,
            rootFolderPath: rootFolderPath,
            monitor: monitor,
            qualityProfileId: qualityProfileID,
            seriesType: seriesType,
            seasonFolder: seasonFolder,
            addOptions: .init(
                monitor: monitor,
                searchForMissingEpisodes: searchForMissingEpisodes,
                searchForCutoffUnmetEpisodes: searchForCutoffUnmetEpisodes
            )
        )

        _ = try await client.send(APIRequest(path: "/api/v3/series", method: "POST", body: try JSONEncoder().encode(payload)), as: SonarrSeriesDTO.self)
    }

    func library() async throws -> [SonarrSeriesDTO] {
        try await client.send(APIRequest(path: "/api/v3/series"), as: [SonarrSeriesDTO].self)
    }
}

private struct SonarrAddSeriesPayload: Encodable {
    let tvdbId: Int
    let rootFolderPath: String
    let monitor: String
    let qualityProfileId: Int
    let seriesType: String
    let seasonFolder: Bool
    let addOptions: SonarrAddSeriesOptionsPayload
}

private struct SonarrAddSeriesOptionsPayload: Encodable {
    let monitor: String
    let searchForMissingEpisodes: Bool
    let searchForCutoffUnmetEpisodes: Bool
}
