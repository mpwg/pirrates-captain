import Foundation

public struct RadarrCalendarDTO: Decodable, Sendable {
    public let title: String
    public let inCinemas: Date?
    public let physicalRelease: Date?
    public let digitalRelease: Date?

    public var releaseDate: Date? {
        inCinemas ?? digitalRelease ?? physicalRelease
    }
}
