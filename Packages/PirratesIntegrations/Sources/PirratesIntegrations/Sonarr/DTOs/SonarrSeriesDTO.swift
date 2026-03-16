import Foundation

public struct SonarrSeriesDTO: Codable, Equatable, Sendable {
    public let title: String
    public let year: Int?
    public let overview: String?
    public let tvdbId: Int?

    public init(title: String, year: Int?, overview: String? = nil, tvdbId: Int? = nil) {
        self.title = title
        self.year = year
        self.overview = overview
        self.tvdbId = tvdbId
    }
}
