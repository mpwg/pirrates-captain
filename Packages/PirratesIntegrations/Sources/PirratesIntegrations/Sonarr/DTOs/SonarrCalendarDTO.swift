import Foundation

public struct SonarrCalendarSeriesDTO: Decodable, Sendable {
    public let title: String
}

public struct SonarrCalendarDTO: Decodable, Sendable {
    public let title: String
    public let airDateUtc: Date
    public let series: SonarrCalendarSeriesDTO?
}
