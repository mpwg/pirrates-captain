import Foundation
import PirratesCore

@MainActor
public final class ServiceHealthChecker: HealthChecking {
    public init() {}

    public func checkHealth(for profiles: [ServerProfile]) async -> [ServiceHealth] {
        profiles.map { profile in
            ServiceHealth(
                service: profile.kind,
                status: profile.isEnabled ? .healthy : .offline,
                message: profile.isEnabled ? "Configured" : "Disabled"
            )
        }
    }
}

@MainActor
public final class DashboardRepository: DashboardProviding {
    private let serverManager: any ServerManaging
    private let healthChecker: any HealthChecking

    public init(serverManager: any ServerManaging, healthChecker: any HealthChecking) {
        self.serverManager = serverManager
        self.healthChecker = healthChecker
    }

    public func loadDashboard() async throws -> DashboardSnapshot {
        let profiles = try serverManager.profiles().filter(\.isEnabled)
        let health = await healthChecker.checkHealth(for: profiles)

        return DashboardSnapshot(
            queueCount: profiles.count * 2,
            recentItems: profiles.map { "\($0.kind.displayName) recently added item" },
            upcomingItems: profiles.map { "\($0.kind.displayName) upcoming release" },
            health: health
        )
    }
}

@MainActor
public final class DiscoverRepository: DiscoverProviding {
    private let serverManager: any ServerManaging

    public init(serverManager: any ServerManaging) {
        self.serverManager = serverManager
    }

    public func search(query: String) async throws -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let profiles = try serverManager.profiles().filter(\.isEnabled)
        return profiles.map {
            SearchResult(title: query, detail: "Search via \($0.kind.displayName)", kind: $0.kind)
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
