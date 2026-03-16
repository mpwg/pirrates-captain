import Foundation
import PirratesCore

@MainActor
public final class ServiceHealthChecker: HealthChecking {
    private let serverManager: any ServerManaging
    private let validator: any ServerConnectionValidating

    public init(serverManager: any ServerManaging, validator: any ServerConnectionValidating) {
        self.serverManager = serverManager
        self.validator = validator
    }

    public func checkHealth(for profiles: [ServerProfile]) async -> [ServiceHealth] {
        var healthStates: [ServiceHealth] = []

        for profile in profiles {
            if !profile.isEnabled {
                healthStates.append(
                    ServiceHealth(serverName: profile.name, service: profile.kind, status: .offline, message: "Disabled")
                )
                continue
            }

            do {
                let apiKey = try serverManager.apiKey(for: profile.id)
                try await validator.validateServer(profile, apiKey: apiKey)
                healthStates.append(
                    ServiceHealth(
                        serverName: profile.name,
                        service: profile.kind,
                        status: profile.allowsInsecureConnections ? .degraded : .healthy,
                        message: profile.allowsInsecureConnections ? "Connected over HTTP" : "Connected"
                    )
                )
            } catch let error as AppError {
                healthStates.append(Self.health(for: profile, error: error))
            } catch {
                healthStates.append(Self.health(for: profile, error: ErrorMapper.map(error)))
            }
        }

        return healthStates
    }

    private static func health(for profile: ServerProfile, error: AppError) -> ServiceHealth {
        switch error {
        case .authenticationFailed:
            ServiceHealth(serverName: profile.name, service: profile.kind, status: .unauthorized, message: error.localizedDescription)
        case .unreachableServer:
            ServiceHealth(serverName: profile.name, service: profile.kind, status: .offline, message: error.localizedDescription)
        case .rateLimited:
            ServiceHealth(serverName: profile.name, service: profile.kind, status: .degraded, message: error.localizedDescription)
        case let .validationFailed(message):
            ServiceHealth(serverName: profile.name, service: profile.kind, status: .degraded, message: message)
        case let .unknown(message):
            ServiceHealth(serverName: profile.name, service: profile.kind, status: .degraded, message: message)
        }
    }
}

@MainActor
public final class DashboardRepository: DashboardProviding {
    private let serverManager: any ServerManaging
    private let healthChecker: any HealthChecking
    private let httpClient: HTTPClient

    public init(
        serverManager: any ServerManaging,
        healthChecker: any HealthChecking,
        httpClient: HTTPClient = URLSession.shared
    ) {
        self.serverManager = serverManager
        self.healthChecker = healthChecker
        self.httpClient = httpClient
    }

    public func loadDashboard() async throws -> DashboardSnapshot {
        let profiles = try serverManager.profiles().filter(\.isEnabled)
        let health = await healthChecker.checkHealth(for: profiles)
        let now = Date()
        let recentWindowStart = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let upcomingWindowEnd = Calendar.current.date(byAdding: .day, value: 14, to: now) ?? now
        var totalQueueCount = 0
        var recentItems: [DashboardItem] = []
        var upcomingItems: [DashboardItem] = []

        for profile in profiles {
            do {
                let apiKey = try serverManager.apiKey(for: profile.id)
                totalQueueCount += try await fetchQueueCount(for: profile, apiKey: apiKey)
                recentItems += try await fetchCalendarItems(
                    for: profile,
                    apiKey: apiKey,
                    start: recentWindowStart,
                    end: now,
                    isUpcoming: false
                )
                upcomingItems += try await fetchCalendarItems(
                    for: profile,
                    apiKey: apiKey,
                    start: now,
                    end: upcomingWindowEnd,
                    isUpcoming: true
                )
            } catch {
                continue
            }
        }

        return DashboardSnapshot(
            queueCount: totalQueueCount,
            recentItems: recentItems.sorted(using: DashboardRepository.recentSort).prefix(6).map(\.self),
            upcomingItems: upcomingItems.sorted(using: DashboardRepository.upcomingSort).prefix(6).map(\.self),
            health: health
        )
    }

    private func fetchQueueCount(for profile: ServerProfile, apiKey: String?) async throws -> Int {
        switch profile.kind {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            return try await SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).queueCount()
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            return try await RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).queueCount()
        case .lidarr, .prowlarr, .sabnzbd:
            return 0
        }
    }

    private func fetchCalendarItems(
        for profile: ServerProfile,
        apiKey: String?,
        start: Date,
        end: Date,
        isUpcoming: Bool
    ) async throws -> [DashboardItem] {
        switch profile.kind {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            let entries = try await SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
                .calendar(start: start, end: end)
            return entries.map { entry in
                DashboardItem(
                    title: entry.series?.title ?? entry.title,
                    detail: isUpcoming ? entry.title : "Aired: \(entry.title)",
                    service: .sonarr,
                    serverName: profile.name,
                    date: entry.airDateUtc
                )
            }
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            let entries = try await RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
                .calendar(start: start, end: end)
            return entries.compactMap { entry in
                guard let date = entry.releaseDate else { return nil }
                return DashboardItem(
                    title: entry.title,
                    detail: isUpcoming ? "Release scheduled" : "Recently released",
                    service: .radarr,
                    serverName: profile.name,
                    date: date
                )
            }
        case .lidarr, .prowlarr, .sabnzbd:
            return []
        }
    }

    private static let recentSort = SortDescriptor(\DashboardItem.date, order: .reverse)
    private static let upcomingSort = SortDescriptor(\DashboardItem.date, order: .forward)
}

@MainActor
public final class DiscoverRepository: DiscoverProviding {
    private let serverManager: any ServerManaging
    private let httpClient: HTTPClient

    public init(serverManager: any ServerManaging, httpClient: HTTPClient = URLSession.shared) {
        self.serverManager = serverManager
        self.httpClient = httpClient
    }

    public func search(query: String) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let profiles = try serverManager.profiles().filter(\.isEnabled)
        var aggregatedResults: [SearchResult] = []

        for profile in profiles {
            let apiKey = try serverManager.apiKey(for: profile.id)
            aggregatedResults += try await search(query: query, profile: profile, apiKey: apiKey)
        }

        return aggregatedResults
    }

    private func search(query: String, profile: ServerProfile, apiKey: String?) async throws -> [SearchResult] {
        switch profile.kind {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else { return [] }
            return try await SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).search(term: query)
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else { return [] }
            return try await RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).search(term: query)
        case .lidarr, .prowlarr, .sabnzbd:
            return []
        }
    }

    public func prepareAdd(for result: SearchResult) async throws -> DiscoverAddContext {
        let profile = try serverManager.profiles().first { $0.id == result.serverID }

        guard let profile else {
            throw AppError.validationFailed("The selected server is no longer configured.")
        }

        let apiKey = try serverManager.apiKey(for: profile.id)

        switch result.addTarget {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            let client = SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
            let rootFolders = try await client.rootFolders()
                .filter(\.accessible)
                .map { DiscoverOption(id: $0.path, title: $0.path) }
            let qualityProfiles = try await client.qualityProfiles()
                .map { DiscoverOption(id: String($0.id), title: $0.name) }

            return DiscoverAddContext(
                title: result.title,
                service: .sonarr,
                serverName: profile.name,
                qualityProfiles: qualityProfiles,
                rootFolders: rootFolders,
                monitorOptions: Self.sonarrMonitorOptions,
                seriesTypeOptions: Self.sonarrSeriesTypeOptions,
                minimumAvailabilityOptions: [],
                defaultConfiguration: DiscoverAddConfiguration(
                    rootFolderPath: rootFolders.first?.id ?? "",
                    qualityProfileID: Int(qualityProfiles.first?.id ?? "") ?? 0,
                    monitor: Self.sonarrMonitorOptions.first?.id ?? "all",
                    seriesType: Self.sonarrSeriesTypeOptions.first?.id ?? "standard",
                    minimumAvailability: "released",
                    seasonFolder: true,
                    searchForMissingEpisodes: true,
                    searchForCutoffUnmetEpisodes: false,
                    searchForMovie: false
                )
            )
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            let client = RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
            let rootFolders = try await client.rootFolders()
                .filter(\.accessible)
                .map { DiscoverOption(id: $0.path, title: $0.path) }
            let qualityProfiles = try await client.qualityProfiles()
                .map { DiscoverOption(id: String($0.id), title: $0.name) }

            return DiscoverAddContext(
                title: result.title,
                service: .radarr,
                serverName: profile.name,
                qualityProfiles: qualityProfiles,
                rootFolders: rootFolders,
                monitorOptions: Self.radarrMonitorOptions,
                seriesTypeOptions: [],
                minimumAvailabilityOptions: Self.radarrMinimumAvailabilityOptions,
                defaultConfiguration: DiscoverAddConfiguration(
                    rootFolderPath: rootFolders.first?.id ?? "",
                    qualityProfileID: Int(qualityProfiles.first?.id ?? "") ?? 0,
                    monitor: Self.radarrMonitorOptions.first?.id ?? "movieOnly",
                    seriesType: "standard",
                    minimumAvailability: Self.radarrMinimumAvailabilityOptions.last?.id ?? "released",
                    seasonFolder: false,
                    searchForMissingEpisodes: false,
                    searchForCutoffUnmetEpisodes: false,
                    searchForMovie: true
                )
            )
        }
    }

    public func add(result: SearchResult, configuration: DiscoverAddConfiguration) async throws {
        let profile = try serverManager.profiles().first { $0.id == result.serverID }

        guard let profile else {
            throw AppError.validationFailed("The selected server is no longer configured.")
        }

        let apiKey = try serverManager.apiKey(for: profile.id)

        switch result.addTarget {
        case let .sonarr(tvdbID):
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            try await SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).addSeries(
                tvdbID: tvdbID,
                rootFolderPath: configuration.rootFolderPath,
                monitor: configuration.monitor,
                qualityProfileID: configuration.qualityProfileID,
                seriesType: configuration.seriesType,
                seasonFolder: configuration.seasonFolder,
                searchForMissingEpisodes: configuration.searchForMissingEpisodes,
                searchForCutoffUnmetEpisodes: configuration.searchForCutoffUnmetEpisodes
            )
        case let .radarr(tmdbID):
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            try await RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).addMovie(
                tmdbID: tmdbID,
                rootFolderPath: configuration.rootFolderPath,
                monitor: configuration.monitor,
                qualityProfileID: configuration.qualityProfileID,
                minimumAvailability: configuration.minimumAvailability,
                searchForMovie: configuration.searchForMovie
            )
        }
    }

    private static let sonarrMonitorOptions = [
        DiscoverOption(id: "all", title: "All episodes"),
        DiscoverOption(id: "future", title: "Future episodes"),
        DiscoverOption(id: "missing", title: "Missing episodes"),
        DiscoverOption(id: "existing", title: "Existing episodes"),
        DiscoverOption(id: "pilot", title: "Pilot only"),
        DiscoverOption(id: "none", title: "None"),
    ]

    private static let sonarrSeriesTypeOptions = [
        DiscoverOption(id: "standard", title: "Standard"),
        DiscoverOption(id: "daily", title: "Daily"),
        DiscoverOption(id: "anime", title: "Anime"),
    ]

    private static let radarrMonitorOptions = [
        DiscoverOption(id: "movieOnly", title: "Movie only"),
        DiscoverOption(id: "movieAndCollection", title: "Movie and collection"),
        DiscoverOption(id: "none", title: "None"),
    ]

    private static let radarrMinimumAvailabilityOptions = [
        DiscoverOption(id: "announced", title: "Announced"),
        DiscoverOption(id: "inCinemas", title: "In cinemas"),
        DiscoverOption(id: "released", title: "Released"),
    ]
}

public struct ArrServerConnectionValidator: ServerConnectionValidating {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = URLSession.shared) {
        self.httpClient = httpClient
    }

    public func validateServer(_ profile: ServerProfile, apiKey: String?) async throws {
        switch profile.kind {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            _ = try await SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).validateConnection()
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            _ = try await RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient).validateConnection()
        case .lidarr, .prowlarr, .sabnzbd:
            return
        }
    }
}

@MainActor
public final class LibraryRepository: LibraryProviding {
    private let serverManager: any ServerManaging
    private let httpClient: HTTPClient

    public init(serverManager: any ServerManaging, httpClient: HTTPClient = URLSession.shared) {
        self.serverManager = serverManager
        self.httpClient = httpClient
    }

    public func loadLibrary() async throws -> [LibraryItem] {
        let profiles = try serverManager.profiles().filter(\.isEnabled)
        var items: [LibraryItem] = []

        for profile in profiles {
            do {
                let apiKey = try serverManager.apiKey(for: profile.id)
                items += try await loadLibrary(for: profile, apiKey: apiKey)
            } catch {
                continue
            }
        }

        return items.sorted {
            if $0.kind == $1.kind {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.kind.displayName < $1.kind.displayName
        }
    }

    private func loadLibrary(for profile: ServerProfile, apiKey: String?) async throws -> [LibraryItem] {
        switch profile.kind {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            return try await SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
                .library()
                .compactMap { SonarrLibraryMapper.map($0, profile: profile) }
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            return try await RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
                .library()
                .compactMap { RadarrLibraryMapper.map($0, profile: profile) }
        case .lidarr, .prowlarr, .sabnzbd:
            return []
        }
    }
}

@MainActor
public final class ActivityRepository: ActivityProviding {
    private let serverManager: any ServerManaging
    private let httpClient: HTTPClient

    public init(serverManager: any ServerManaging, httpClient: HTTPClient = URLSession.shared) {
        self.serverManager = serverManager
        self.httpClient = httpClient
    }

    public func loadActivity() async throws -> [ActivityItem] {
        let profiles = try serverManager.profiles().filter(\.isEnabled)
        var items: [ActivityItem] = []
        var lastError: Error?
        var attemptedServers = 0

        for profile in profiles {
            if profile.kind == .sonarr || profile.kind == .radarr {
                attemptedServers += 1
            }

            do {
                let apiKey = try serverManager.apiKey(for: profile.id)
                items += try await loadActivity(for: profile, apiKey: apiKey)
            } catch {
                lastError = error
            }
        }

        if items.isEmpty, attemptedServers > 0, let lastError {
            throw lastError
        }

        return items.sorted(using: SortDescriptor(\ActivityItem.date, order: .reverse))
    }

    private func loadActivity(for profile: ServerProfile, apiKey: String?) async throws -> [ActivityItem] {
        switch profile.kind {
        case .sonarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Sonarr.")
            }
            let client = SonarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
            let queueItems = try await client.queue().compactMap { SonarrActivityMapper.mapQueue($0, profile: profile) }
            let historyItems = try await client.history().compactMap { SonarrActivityMapper.mapHistory($0, profile: profile) }
            return Array((queueItems + historyItems).sorted(using: SortDescriptor(\.date, order: .reverse)).prefix(12))
        case .radarr:
            guard let apiKey, !apiKey.isEmpty else {
                throw AppError.validationFailed("An API key is required for Radarr.")
            }
            let client = RadarrClient(profile: profile, apiKey: apiKey, httpClient: httpClient)
            let queueItems = try await client.queue().compactMap { RadarrActivityMapper.mapQueue($0, profile: profile) }
            let historyItems = try await client.history().compactMap { RadarrActivityMapper.mapHistory($0, profile: profile) }
            return Array((queueItems + historyItems).sorted(using: SortDescriptor(\.date, order: .reverse)).prefix(12))
        case .lidarr, .prowlarr, .sabnzbd:
            return []
        }
    }
}
