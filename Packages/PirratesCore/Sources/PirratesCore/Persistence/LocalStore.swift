import Foundation
import SwiftData

@Model
public final class StoredServerProfile {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var kindRawValue: String
    public var baseURLString: String
    public var allowsInsecureConnections: Bool
    public var isEnabled: Bool

    public init(from profile: ServerProfile) {
        self.id = profile.id
        self.name = profile.name
        self.kindRawValue = profile.kind.rawValue
        self.baseURLString = profile.baseURL.absoluteString
        self.allowsInsecureConnections = profile.allowsInsecureConnections
        self.isEnabled = profile.isEnabled
    }

    public func update(from profile: ServerProfile) {
        id = profile.id
        name = profile.name
        kindRawValue = profile.kind.rawValue
        baseURLString = profile.baseURL.absoluteString
        allowsInsecureConnections = profile.allowsInsecureConnections
        isEnabled = profile.isEnabled
    }

    public var asDomainModel: ServerProfile? {
        guard
            let kind = ServiceKind(rawValue: kindRawValue),
            let url = URL(string: baseURLString)
        else {
            return nil
        }

        return ServerProfile(
            id: id,
            name: name,
            kind: kind,
            baseURL: url,
            allowsInsecureConnections: allowsInsecureConnections,
            isEnabled: isEnabled
        )
    }
}

public enum AppModelContainer {
    @MainActor
    public static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([StoredServerProfile.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

@MainActor
public final class LocalServerManager: ServerManaging {
    private let modelContext: ModelContext
    private let secretStore: SecretStoring

    public init(modelContext: ModelContext, secretStore: SecretStoring) {
        self.modelContext = modelContext
        self.secretStore = secretStore
    }

    public func profiles() throws -> [ServerProfile] {
        let descriptor = FetchDescriptor<StoredServerProfile>(
            sortBy: [SortDescriptor(\StoredServerProfile.name)]
        )
        return try modelContext.fetch(descriptor).compactMap(\.asDomainModel)
    }

    public func saveServer(_ profile: ServerProfile, apiKey: String?) throws {
        if let existing = try fetchStoredProfile(id: profile.id) {
            existing.update(from: profile)
        } else {
            modelContext.insert(StoredServerProfile(from: profile))
        }

        if let apiKey {
            try secretStore.saveSecret(apiKey, for: secretKey(for: profile.id))
        }

        try modelContext.save()
    }

    public func deleteServer(id: UUID) throws {
        if let existing = try fetchStoredProfile(id: id) {
            modelContext.delete(existing)
            try modelContext.save()
        }
        try secretStore.deleteSecret(for: secretKey(for: id))
    }

    public func apiKey(for id: UUID) throws -> String? {
        try secretStore.readSecret(for: secretKey(for: id))
    }

    private func fetchStoredProfile(id: UUID) throws -> StoredServerProfile? {
        let descriptor = FetchDescriptor<StoredServerProfile>()
        return try modelContext.fetch(descriptor).first(where: { $0.id == id })
    }

    private func secretKey(for id: UUID) -> String {
        "server-api-key-\(id.uuidString)"
    }
}
