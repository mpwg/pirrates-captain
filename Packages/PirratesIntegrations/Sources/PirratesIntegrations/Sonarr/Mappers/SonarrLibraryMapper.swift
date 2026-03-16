import PirratesCore

enum SonarrLibraryMapper {
    static func map(_ dto: SonarrSeriesDTO, profile: ServerProfile) -> LibraryItem? {
        guard let tvdbID = dto.tvdbId else {
            return nil
        }

        let subtitleParts = [
            dto.year.map(String.init),
            dto.status,
            dto.network,
            profile.name,
        ].compactMap { $0 }

        return LibraryItem(
            title: dto.title,
            detail: subtitleParts.joined(separator: " • "),
            kind: .sonarr,
            serverName: profile.name,
            remoteID: String(tvdbID),
            overview: dto.overview ?? "No overview available."
        )
    }
}
