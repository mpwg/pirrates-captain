import Foundation
import PirratesCore

public enum SonarrSeriesMapper {
    public static func map(_ dto: SonarrSeriesDTO) -> SearchResult {
        SearchResult(
            title: dto.title,
            detail: dto.year.map(String.init) ?? "Unknown year",
            kind: .sonarr
        )
    }
}
