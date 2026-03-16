import Foundation

public struct RadarrMovieDTO: Codable, Equatable, Sendable {
    public let title: String
    public let year: Int?
    public let overview: String?
    public let tmdbId: Int?
    public let status: String?
    public let studio: String?

    public init(
        title: String,
        year: Int?,
        overview: String? = nil,
        tmdbId: Int? = nil,
        status: String? = nil,
        studio: String? = nil
    ) {
        self.title = title
        self.year = year
        self.overview = overview
        self.tmdbId = tmdbId
        self.status = status
        self.studio = studio
    }
}
