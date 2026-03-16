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

    var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var requiresAPIKey: Bool {
        switch kind {
        case .sonarr, .radarr:
            true
        case .lidarr, .prowlarr, .sabnzbd:
            false
        }
    }

    var supportsLiveValidation: Bool {
        switch kind {
        case .sonarr, .radarr:
            true
        case .lidarr, .prowlarr, .sabnzbd:
            false
        }
    }

    var validationMessages: [String] {
        var messages: [String] = []

        if trimmedName.isEmpty {
            messages.append("A server name is required.")
        }

        if trimmedBaseURL.isEmpty {
            messages.append("A server URL is required.")
        } else {
            do {
                _ = try normalizedURL()
            } catch let error as AppError {
                messages.append(error.localizedDescription)
            } catch {
                messages.append(error.localizedDescription)
            }
        }

        if requiresAPIKey && trimmedAPIKey.isEmpty {
            messages.append("An API key is required for \(kind.displayName).")
        }

        if !supportsLiveValidation {
            messages.append("\(kind.displayName) validation is not implemented in the MVP yet.")
        }

        return messages
    }

    func makeProfile() throws -> ServerProfile {
        guard !trimmedName.isEmpty else {
            throw AppError.validationFailed("A server name is required.")
        }

        if requiresAPIKey && trimmedAPIKey.isEmpty {
            throw AppError.validationFailed("An API key is required for \(kind.displayName).")
        }

        return ServerProfile(
            id: id ?? UUID(),
            name: trimmedName,
            kind: kind,
            baseURL: try normalizedURL(),
            allowsInsecureConnections: allowsInsecureConnections,
            isEnabled: isEnabled
        )
    }

    private func normalizedURL() throws -> URL {
        guard let components = URLComponents(string: trimmedBaseURL), let scheme = components.scheme?.lowercased() else {
            throw AppError.validationFailed("Enter a valid server URL.")
        }

        guard scheme == "https" || scheme == "http" else {
            throw AppError.validationFailed("Only HTTP and HTTPS server URLs are supported.")
        }

        guard let host = components.host, !host.isEmpty else {
            throw AppError.validationFailed("The server URL must include a host.")
        }

        if scheme == "http" && !allowsInsecureConnections {
            throw AppError.validationFailed("Enable insecure connections if the server uses HTTP.")
        }

        var normalizedComponents = components
        normalizedComponents.scheme = scheme
        normalizedComponents.host = host
        normalizedComponents.query = nil
        normalizedComponents.fragment = nil

        if normalizedComponents.path == "/" {
            normalizedComponents.path = ""
        }

        guard let url = normalizedComponents.url else {
            throw AppError.validationFailed("Could not normalize the server URL.")
        }

        return url
    }
}
