import Foundation
import PirratesCore

public enum RadarrMovieMapper {
    public static func map(_ dto: RadarrMovieDTO, profile: ServerProfile) -> SearchResult? {
        guard let tmdbID = dto.tmdbId else {
            return nil
        }

        return SearchResult(
            title: dto.title,
            detail: dto.year.map(String.init) ?? "Unknown year",
            overview: dto.overview ?? "No overview available.",
            kind: .radarr,
            serverID: profile.id,
            serverName: profile.name,
            addTarget: .radarr(tmdbID: tmdbID)
        )
    }
}
