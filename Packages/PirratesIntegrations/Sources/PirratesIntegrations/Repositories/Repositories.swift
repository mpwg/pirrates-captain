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
                healthStates.append(ServiceHealth(service: profile.kind, status: .offline, message: "Disabled"))
                continue
            }

            do {
                let apiKey = try serverManager.apiKey(for: profile.id)
                try await validator.validateServer(profile, apiKey: apiKey)
                healthStates.append(
                    ServiceHealth(
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
            ServiceHealth(service: profile.kind, status: .unauthorized, message: error.localizedDescription)
        case .unreachableServer:
            ServiceHealth(service: profile.kind, status: .offline, message: error.localizedDescription)
        case .rateLimited:
            ServiceHealth(service: profile.kind, status: .degraded, message: error.localizedDescription)
        case let .validationFailed(message):
            ServiceHealth(service: profile.kind, status: .degraded, message: message)
        case let .unknown(message):
            ServiceHealth(service: profile.kind, status: .degraded, message: message)
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
        var totalQueueCount = 0

        for profile in profiles {
            let apiKey = try serverManager.apiKey(for: profile.id)
            totalQueueCount += try await fetchQueueCount(for: profile, apiKey: apiKey)
        }

        return DashboardSnapshot(
            queueCount: totalQueueCount,
            recentItems: [],
            upcomingItems: [],
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

    public init(serverManager: any ServerManaging) {
        self.serverManager = serverManager
    }

    public func loadLibrary() async throws -> [LibraryItem] {
        try serverManager.profiles()
            .filter(\.isEnabled)
            .map { LibraryItem(title: "\($0.kind.displayName) library", detail: $0.name, kind: $0.kind) }
    }
}

@MainActor
public final class ActivityRepository: ActivityProviding {
    private let serverManager: any ServerManaging

    public init(serverManager: any ServerManaging) {
        self.serverManager = serverManager
    }

    public func loadActivity() async throws -> [ActivityItem] {
        try serverManager.profiles()
            .filter(\.isEnabled)
            .map {
                ActivityItem(
                    title: "\($0.kind.displayName) download",
                    detail: "Monitoring \($0.name)",
                    progress: 0.65
                )
            }
    }
}
