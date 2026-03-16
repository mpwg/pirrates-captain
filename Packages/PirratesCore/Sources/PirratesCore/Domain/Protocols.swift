import Foundation

@MainActor
public protocol ServerManaging: AnyObject {
    func profiles() throws -> [ServerProfile]
    func saveServer(_ profile: ServerProfile, apiKey: String?) throws
    func deleteServer(id: UUID) throws
    func apiKey(for id: UUID) throws -> String?
}

@MainActor
public protocol DashboardProviding {
    func loadDashboard() async throws -> DashboardSnapshot
}

@MainActor
public protocol DiscoverProviding {
    func search(query: String) async throws -> [SearchResult]
    func prepareAdd(for result: SearchResult) async throws -> DiscoverAddContext
    func add(result: SearchResult, configuration: DiscoverAddConfiguration) async throws
}

@MainActor
public protocol LibraryProviding {
    func loadLibrary() async throws -> [LibraryItem]
}

@MainActor
public protocol ActivityProviding {
    func loadActivity() async throws -> [ActivityItem]
}

@MainActor
public protocol HealthChecking {
    func checkHealth(for profiles: [ServerProfile]) async -> [ServiceHealth]
}

public protocol ServerConnectionValidating: Sendable {
    func validateServer(_ profile: ServerProfile, apiKey: String?) async throws
}

public protocol SecretStoring {
    func saveSecret(_ value: String, for key: String) throws
    func readSecret(for key: String) throws -> String?
    func deleteSecret(for key: String) throws
}
