import Foundation
import Testing
@testable import PirratesCore

@MainActor
struct InMemoryServerManagerTests {
    @Test
    func savesAndDeletesServers() throws {
        let manager = InMemoryServerManager()
        let profile = Fixtures.sonarrServer

        try manager.saveServer(profile, apiKey: "secret")

        #expect(try manager.profiles() == [profile])
        #expect(try manager.apiKey(for: profile.id) == "secret")

        try manager.deleteServer(id: profile.id)

        #expect(try manager.profiles().isEmpty)
        #expect(try manager.apiKey(for: profile.id) == nil)
    }
}
