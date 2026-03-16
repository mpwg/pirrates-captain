import Foundation

struct SonarrQueuePageDTO: Decodable, Sendable {
    let records: [SonarrQueueRecordDTO]?
}

struct SonarrQueueRecordDTO: Decodable, Sendable {
    let id: Int?
    let title: String?
    let status: String?
    let trackedDownloadStatus: String?
    let trackedDownloadState: String?
    let size: Double?
    let sizeleft: Double?
    let timeleft: String?
    let estimatedCompletionTime: Date?
    let series: SonarrQueueSeriesDTO?
    let episode: SonarrQueueEpisodeDTO?
}

struct SonarrQueueSeriesDTO: Decodable, Sendable {
    let title: String?
}

struct SonarrQueueEpisodeDTO: Decodable, Sendable {
    let title: String?
}
