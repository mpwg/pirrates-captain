import Foundation
import PirratesCore

public enum RadarrMovieMapper {
    public static func map(_ dto: RadarrMovieDTO) -> SearchResult {
        SearchResult(
            title: dto.title,
            detail: dto.year.map(String.init) ?? "Unknown year",
            kind: .radarr
        )
    }
}
