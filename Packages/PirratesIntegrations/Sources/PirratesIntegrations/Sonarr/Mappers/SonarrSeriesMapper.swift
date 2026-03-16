import Foundation
import PirratesCore

public enum SonarrSeriesMapper {
    public static func map(_ dto: SonarrSeriesDTO, profile: ServerProfile) -> SearchResult? {
        guard let tvdbID = dto.tvdbId else {
            return nil
        }

        return SearchResult(
            title: dto.title,
            detail: dto.year.map(String.init) ?? "Unknown year",
            overview: dto.overview ?? "No overview available.",
            kind: .sonarr,
            serverID: profile.id,
            serverName: profile.name,
            addTarget: .sonarr(tvdbID: tvdbID)
        )
    }
}
