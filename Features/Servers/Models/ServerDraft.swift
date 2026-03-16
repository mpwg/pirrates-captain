import Foundation
import PirratesCore

struct ServerDraft: Equatable {
    var id: UUID?
    var name = ""
    var kind: ServiceKind = .sonarr
    var baseURL = ""
    var apiKey = ""
    var allowsInsecureConnections = false
    var isEnabled = true

    init() {}

    init(profile: ServerProfile, apiKey: String?) {
        id = profile.id
        name = profile.name
        kind = profile.kind
        baseURL = profile.baseURL.absoluteString
        self.apiKey = apiKey ?? ""
        allowsInsecureConnections = profile.allowsInsecureConnections
        isEnabled = profile.isEnabled
    }

    var isEditing: Bool {
        id != nil
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func makeProfile() throws -> ServerProfile {
        guard !trimmedName.isEmpty else {
            throw AppError.validationFailed("A server name is required.")
        }

        guard let url = URL(string: trimmedBaseURL), let scheme = url.scheme else {
            throw AppError.validationFailed("Enter a valid server URL.")
        }

        let normalizedScheme = scheme.lowercased()
        guard normalizedScheme == "https" || normalizedScheme == "http" else {
            throw AppError.validationFailed("Only HTTP and HTTPS server URLs are supported.")
        }

        if normalizedScheme == "http" && !allowsInsecureConnections {
            throw AppError.validationFailed("Enable insecure connections if the server uses HTTP.")
        }

        return ServerProfile(
            id: id ?? UUID(),
            name: trimmedName,
            kind: kind,
            baseURL: url,
            allowsInsecureConnections: allowsInsecureConnections,
            isEnabled: isEnabled
        )
    }
}
