import Foundation
import Observation
import PirratesCore

@MainActor
@Observable
final class ServersViewModel {
    var servers: [ServerProfile] = []
    var errorMessage: String?
    var editorErrorMessage: String?
    var isPresentingEditor = false
    var draft = ServerDraft()

    private let serverManager: any ServerManaging

    init(serverManager: any ServerManaging) {
        self.serverManager = serverManager
        reload()
    }

    func reload() {
        do {
            servers = try serverManager.profiles()
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

    func saveDraft() -> Bool {
        do {
            let profile = try draft.makeProfile()
            let apiKey = draft.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try serverManager.saveServer(profile, apiKey: apiKey.isEmpty ? nil : apiKey)
            cancelEditing()
            reload()
            return true
        } catch {
            editorErrorMessage = ErrorMapper.map(error).localizedDescription
            return false
        }
    }

    func cancelEditing() {
        draft = ServerDraft()
        editorErrorMessage = nil
        isPresentingEditor = false
    }

    func deleteServers(at offsets: IndexSet) {
        for index in offsets {
            do {
                try serverManager.deleteServer(id: servers[index].id)
            } catch {
                errorMessage = ErrorMapper.map(error).localizedDescription
            }
        }
        reload()
    }
}
