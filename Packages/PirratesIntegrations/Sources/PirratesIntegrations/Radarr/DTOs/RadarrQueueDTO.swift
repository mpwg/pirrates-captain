import Foundation

struct RadarrQueuePageDTO: Decodable, Sendable {
    let records: [RadarrQueueRecordDTO]?
}

struct RadarrQueueRecordDTO: Decodable, Sendable {
    let id: Int?
    let title: String?
    let status: String?
    let trackedDownloadStatus: String?
    let trackedDownloadState: String?
    let size: Double?
    let sizeleft: Double?
    let timeleft: String?
    let estimatedCompletionTime: Date?
    let movie: RadarrQueueMovieDTO?
}

struct RadarrQueueMovieDTO: Decodable, Sendable {
    let title: String?
}
