import Foundation
import Observation
import PirratesCore

@MainActor
@Observable
final class ServersViewModel {
    var servers: [ServerProfile] = []
    var errorMessage: String?

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

    func addSampleServer() {
        let nextKind = ServiceKind.allCases[servers.count % ServiceKind.allCases.count]
        let profile = ServerProfile(
            name: "\(nextKind.displayName) Server",
            kind: nextKind,
            baseURL: URL(string: "https://\(nextKind.rawValue).local")!
        )

        do {
            try serverManager.saveServer(profile, apiKey: nil)
            reload()
        } catch {
            errorMessage = ErrorMapper.map(error).localizedDescription
        }
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
