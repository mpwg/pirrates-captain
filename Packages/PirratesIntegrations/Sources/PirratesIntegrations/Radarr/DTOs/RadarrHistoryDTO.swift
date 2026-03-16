import Foundation

struct RadarrHistoryPageDTO: Decodable, Sendable {
    let records: [RadarrHistoryRecordDTO]?
}

struct RadarrHistoryRecordDTO: Decodable, Sendable {
    let id: Int?
    let sourceTitle: String?
    let eventType: String?
    let date: Date?
    let movie: RadarrHistoryMovieDTO?
}

struct RadarrHistoryMovieDTO: Decodable, Sendable {
    let title: String?
}
