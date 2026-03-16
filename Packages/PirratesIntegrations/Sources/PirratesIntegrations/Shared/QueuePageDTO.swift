import Foundation

struct QueuePageDTO: Decodable, Sendable {
    let totalRecords: Int?
    let records: [QueueRecordDTO]?
}

struct QueueRecordDTO: Decodable, Sendable {
    let id: Int?
}
