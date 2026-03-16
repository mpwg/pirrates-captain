import Foundation

public struct RadarrMovieDTO: Codable, Equatable, Sendable {
    public let title: String
    public let year: Int?

    public init(title: String, year: Int?) {
        self.title = title
        self.year = year
    }
}
