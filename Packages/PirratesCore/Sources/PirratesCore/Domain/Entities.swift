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
    public let kind: ServiceKind

    public init(id: UUID = UUID(), title: String, detail: String, kind: ServiceKind) {
        self.id = id
        self.title = title
        self.detail = detail
        self.kind = kind
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
