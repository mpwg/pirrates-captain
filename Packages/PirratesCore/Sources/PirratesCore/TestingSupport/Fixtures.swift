import Foundation

public enum Fixtures {
    public static let sonarrServer = ServerProfile(
        name: "Local Sonarr",
        kind: .sonarr,
        baseURL: URL(string: "https://sonarr.local")!
    )

    public static let radarrServer = ServerProfile(
        name: "Local Radarr",
        kind: .radarr,
        baseURL: URL(string: "https://radarr.local")!
    )
}

@MainActor
public final class InMemoryServerManager: ServerManaging {
    private var storedProfiles: [ServerProfile]
    private var secrets: [UUID: String]

    public init(
        storedProfiles: [ServerProfile] = [],
        secrets: [UUID: String] = [:]
    ) {
        self.storedProfiles = storedProfiles
        self.secrets = secrets
    }

    public func profiles() throws -> [ServerProfile] {
        storedProfiles.sorted { $0.name < $1.name }
    }

    public func saveServer(_ profile: ServerProfile, apiKey: String?) throws {
        if let index = storedProfiles.firstIndex(where: { $0.id == profile.id }) {
            storedProfiles[index] = profile
        } else {
            storedProfiles.append(profile)
        }

        if let apiKey {
            secrets[profile.id] = apiKey
        }
    }

    public func deleteServer(id: UUID) throws {
        storedProfiles.removeAll { $0.id == id }
        secrets[id] = nil
    }

    public func apiKey(for id: UUID) throws -> String? {
        secrets[id]
    }
}
