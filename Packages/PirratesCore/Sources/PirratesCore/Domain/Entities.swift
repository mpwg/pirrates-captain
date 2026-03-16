import Foundation

public enum ServiceKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case sonarr
    case radarr
    case lidarr
    case prowlarr
    case sabnzbd

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sonarr: "Sonarr"
        case .radarr: "Radarr"
        case .lidarr: "Lidarr"
        case .prowlarr: "Prowlarr"
        case .sabnzbd: "SABnzbd"
        }
    }
}

public struct ServerProfile: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var kind: ServiceKind
    public var baseURL: URL
    public var allowsInsecureConnections: Bool
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        kind: ServiceKind,
        baseURL: URL,
        allowsInsecureConnections: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseURL = baseURL
        self.allowsInsecureConnections = allowsInsecureConnections
        self.isEnabled = isEnabled
    }
}

public struct ServiceHealth: Identifiable, Equatable, Sendable {
    public enum Status: String, Sendable {
        case healthy
        case degraded
        case offline
        case unauthorized
    }

    public let id: UUID
    public let serverName: String
    public let service: ServiceKind
    public let status: Status
    public let message: String

    public init(id: UUID = UUID(), serverName: String, service: ServiceKind, status: Status, message: String) {
        self.id = id
        self.serverName = serverName
        self.service = service
        self.status = status
        self.message = message
    }
}

public struct DashboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let service: ServiceKind
    public let serverName: String
    public let date: Date

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        service: ServiceKind,
        serverName: String,
        date: Date
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.service = service
        self.serverName = serverName
        self.date = date
    }
}

public struct DashboardSnapshot: Equatable, Sendable {
    public let queueCount: Int
    public let recentItems: [DashboardItem]
    public let upcomingItems: [DashboardItem]
    public let health: [ServiceHealth]

    public init(
        queueCount: Int,
        recentItems: [DashboardItem],
        upcomingItems: [DashboardItem],
        health: [ServiceHealth]
    ) {
        self.queueCount = queueCount
        self.recentItems = recentItems
        self.upcomingItems = upcomingItems
        self.health = health
    }
}

public struct SearchResult: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let overview: String
    public let kind: ServiceKind
    public let serverID: UUID
    public let serverName: String
    public let addTarget: SearchResultAddTarget

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        overview: String,
        kind: ServiceKind,
        serverID: UUID,
        serverName: String,
        addTarget: SearchResultAddTarget
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.overview = overview
        self.kind = kind
        self.serverID = serverID
        self.serverName = serverName
        self.addTarget = addTarget
    }
}

public enum SearchResultAddTarget: Equatable, Sendable {
    case sonarr(tvdbID: Int)
    case radarr(tmdbID: Int)
}

public struct DiscoverOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?

    public init(id: String, title: String, subtitle: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}

public struct DiscoverAddConfiguration: Equatable, Sendable {
    public var rootFolderPath: String
    public var qualityProfileID: Int
    public var monitor: String
    public var seriesType: String
    public var minimumAvailability: String
    public var seasonFolder: Bool
    public var searchForMissingEpisodes: Bool
    public var searchForCutoffUnmetEpisodes: Bool
    public var searchForMovie: Bool

    public init(
        rootFolderPath: String,
        qualityProfileID: Int,
        monitor: String,
        seriesType: String,
        minimumAvailability: String,
        seasonFolder: Bool,
        searchForMissingEpisodes: Bool,
        searchForCutoffUnmetEpisodes: Bool,
        searchForMovie: Bool
    ) {
        self.rootFolderPath = rootFolderPath
        self.qualityProfileID = qualityProfileID
        self.monitor = monitor
        self.seriesType = seriesType
        self.minimumAvailability = minimumAvailability
        self.seasonFolder = seasonFolder
        self.searchForMissingEpisodes = searchForMissingEpisodes
        self.searchForCutoffUnmetEpisodes = searchForCutoffUnmetEpisodes
        self.searchForMovie = searchForMovie
    }
}

public struct DiscoverAddContext: Equatable, Sendable {
    public let title: String
    public let service: ServiceKind
    public let serverName: String
    public let qualityProfiles: [DiscoverOption]
    public let rootFolders: [DiscoverOption]
    public let monitorOptions: [DiscoverOption]
    public let seriesTypeOptions: [DiscoverOption]
    public let minimumAvailabilityOptions: [DiscoverOption]
    public let defaultConfiguration: DiscoverAddConfiguration

    public init(
        title: String,
        service: ServiceKind,
        serverName: String,
        qualityProfiles: [DiscoverOption],
        rootFolders: [DiscoverOption],
        monitorOptions: [DiscoverOption],
        seriesTypeOptions: [DiscoverOption],
        minimumAvailabilityOptions: [DiscoverOption],
        defaultConfiguration: DiscoverAddConfiguration
    ) {
        self.title = title
        self.service = service
        self.serverName = serverName
        self.qualityProfiles = qualityProfiles
        self.rootFolders = rootFolders
        self.monitorOptions = monitorOptions
        self.seriesTypeOptions = seriesTypeOptions
        self.minimumAvailabilityOptions = minimumAvailabilityOptions
        self.defaultConfiguration = defaultConfiguration
    }
}

public struct LibraryItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let kind: ServiceKind

    public init(id: UUID = UUID(), title: String, detail: String, kind: ServiceKind) {
        self.id = id
        self.title = title
        self.detail = detail
        self.kind = kind
    }
}

public struct ActivityItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let progress: Double

    public init(id: UUID = UUID(), title: String, detail: String, progress: Double) {
        self.id = id
        self.title = title
        self.detail = detail
        self.progress = progress
    }
}

public enum AppError: Error, Equatable, Sendable {
    case unreachableServer
    case authenticationFailed
    case validationFailed(String)
    case rateLimited
    case unknown(String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unreachableServer:
            "The server could not be reached."
        case .authenticationFailed:
            "Authentication failed."
        case let .validationFailed(message):
            message
        case .rateLimited:
            "The service rate limited the request."
        case let .unknown(message):
            message
        }
    }
}
