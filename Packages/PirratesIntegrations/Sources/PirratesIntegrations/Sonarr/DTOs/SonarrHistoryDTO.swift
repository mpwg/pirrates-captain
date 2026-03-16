import Foundation

struct SonarrHistoryPageDTO: Decodable, Sendable {
    let records: [SonarrHistoryRecordDTO]?
}

struct SonarrHistoryRecordDTO: Decodable, Sendable {
    let id: Int?
    let sourceTitle: String?
    let eventType: String?
    let date: Date?
    let series: SonarrHistorySeriesDTO?
    let episode: SonarrHistoryEpisodeDTO?
}

struct SonarrHistorySeriesDTO: Decodable, Sendable {
    let title: String?
}

struct SonarrHistoryEpisodeDTO: Decodable, Sendable {
    let title: String?
}
