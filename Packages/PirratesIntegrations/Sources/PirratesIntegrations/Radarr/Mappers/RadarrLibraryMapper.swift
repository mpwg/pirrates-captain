import PirratesCore

enum RadarrLibraryMapper {
    static func map(_ dto: RadarrMovieDTO, profile: ServerProfile) -> LibraryItem? {
        guard let tmdbID = dto.tmdbId else {
            return nil
        }

        let subtitleParts = [
            dto.year.map(String.init),
            dto.status,
            dto.studio,
            profile.name,
        ].compactMap { $0 }

        return LibraryItem(
            title: dto.title,
            detail: subtitleParts.joined(separator: " • "),
            kind: .radarr,
            serverName: profile.name,
            remoteID: String(tmdbID),
            overview: dto.overview ?? "No overview available."
        )
    }
}
