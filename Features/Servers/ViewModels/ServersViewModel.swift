import Foundation
import Observation
import PirratesCore

@MainActor
@Observable
final class ServersViewModel {
    struct ValidationState: Equatable {
        enum Kind: Equatable {
            case unchecked
            case checking
            case healthy
            case disabled
            case unsupported
            case offline
            case unauthorized
            case degraded
        }

        let kind: Kind
        let message: String
    }

    var servers: [ServerProfile] = []
    var errorMessage: String?
    var editorErrorMessage: String?
    var isPresentingEditor = false
    var isSaving = false
    var draft = ServerDraft()
    var validationStates: [UUID: ValidationState] = [:]

    private let serverManager: any ServerManaging
    private let serverValidator: any ServerConnectionValidating

    init(serverManager: any ServerManaging, serverValidator: any ServerConnectionValidating) {
        self.serverManager = serverManager
        self.serverValidator = serverValidator
        reload()
    }

    func reload() {
        do {
            servers = try serverManager.profiles()
            validationStates = validationStates.filter { id, _ in
                servers.contains(where: { $0.id == id })
            }
            errorMessage = nil
        } catch {
            errorMessage = ErrorMapper.map(error).localizedDescription
        }
    }

    func presentAddServer() {
        draft = ServerDraft()
        editorErrorMessage = nil
        isPresentingEditor = true
    }

    func presentEditServer(_ server: ServerProfile) {
        do {
            draft = ServerDraft(profile: server, apiKey: try serverManager.apiKey(for: server.id))
            editorErrorMessage = nil
            isPresentingEditor = true
        } catch {
            errorMessage = ErrorMapper.map(error).localizedDescription
        }
    }

    func saveDraft() async -> Bool {
        do {
            isSaving = true
            let profile = try draft.makeProfile()
            let apiKey = draft.trimmedAPIKey

            if draft.supportsLiveValidation && profile.isEnabled {
                try await serverValidator.validateServer(profile, apiKey: apiKey.isEmpty ? nil : apiKey)
            }

            try serverManager.saveServer(profile, apiKey: apiKey.isEmpty ? nil : apiKey)
            cancelEditing()
            reload()
            validationStates[profile.id] = makeValidationState(for: profile, error: nil)
            isSaving = false
            return true
        } catch {
            editorErrorMessage = ErrorMapper.map(error).localizedDescription
            isSaving = false
            return false
        }
    }

    func cancelEditing() {
        draft = ServerDraft()
        editorErrorMessage = nil
        isSaving = false
        isPresentingEditor = false
    }

    func deleteServers(at offsets: IndexSet) {
        for index in offsets {
            let server = servers[index]
            do {
                try serverManager.deleteServer(id: server.id)
                validationStates.removeValue(forKey: server.id)
            } catch {
                errorMessage = ErrorMapper.map(error).localizedDescription
            }
        }
        reload()
    }

    func validationState(for server: ServerProfile) -> ValidationState {
        validationStates[server.id] ?? makeValidationState(for: server, error: nil)
    }

    func toggleServerEnabled(_ server: ServerProfile) async {
        var updated = server
        updated.isEnabled.toggle()

        do {
            let apiKey = try serverManager.apiKey(for: server.id)
            try serverManager.saveServer(updated, apiKey: apiKey)
            reload()

            if updated.isEnabled {
                await revalidateServer(updated)
            } else {
                validationStates[updated.id] = makeValidationState(for: updated, error: nil)
            }
        } catch {
            errorMessage = ErrorMapper.map(error).localizedDescription
        }
    }

    func revalidateServer(_ server: ServerProfile) async {
        guard server.isEnabled else {
            validationStates[server.id] = makeValidationState(for: server, error: nil)
            return
        }

        guard supportsLiveValidation(server.kind) else {
            validationStates[server.id] = makeValidationState(for: server, error: nil)
            return
        }

        validationStates[server.id] = ValidationState(kind: .checking, message: "Checking connection...")

        do {
            let apiKey = try serverManager.apiKey(for: server.id)
            try await serverValidator.validateServer(server, apiKey: apiKey)
            validationStates[server.id] = ValidationState(kind: .healthy, message: "Connection verified.")
            errorMessage = nil
        } catch {
            let appError = ErrorMapper.map(error)
            validationStates[server.id] = makeValidationState(for: server, error: appError)
            errorMessage = appError.localizedDescription
        }
    }

    private func makeValidationState(for server: ServerProfile, error: AppError?) -> ValidationState {
        if !server.isEnabled {
            return ValidationState(kind: .disabled, message: "Server disabled.")
        }

        if !supportsLiveValidation(server.kind) {
            return ValidationState(kind: .unsupported, message: "\(server.kind.displayName) validation is not implemented in the MVP yet.")
        }

        guard let error else {
            return ValidationState(kind: .unchecked, message: "Connection not checked yet.")
        }

        switch error {
        case .unreachableServer:
            return ValidationState(kind: .offline, message: error.localizedDescription)
        case .authenticationFailed:
            return ValidationState(kind: .unauthorized, message: error.localizedDescription)
        case .rateLimited, .validationFailed(_), .unknown(_):
            return ValidationState(kind: .degraded, message: error.localizedDescription)
        }
    }

    private func supportsLiveValidation(_ kind: ServiceKind) -> Bool {
        switch kind {
        case .sonarr, .radarr:
            true
        case .lidarr, .prowlarr, .sabnzbd:
            false
        }
    }
}
