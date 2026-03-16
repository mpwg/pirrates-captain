import Foundation

public struct RadarrMovieDTO: Codable, Equatable, Sendable {
    public let title: String
    public let year: Int?
    public let overview: String?
    public let tmdbId: Int?

    public init(title: String, year: Int?, overview: String? = nil, tmdbId: Int? = nil) {
        self.title = title
        self.year = year
        self.overview = overview
        self.tmdbId = tmdbId
    }
}
