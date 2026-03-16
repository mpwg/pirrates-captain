import Testing
import PirratesCore
@testable import PirratesIntegrations

@MainActor
struct MappingAndRepositoryTests {
    @Test
    func mapsSonarrSeriesIntoSearchResult() {
        let dto = SonarrSeriesDTO(title: "Andor", year: 2022)
        let result = SonarrSeriesMapper.map(dto)

        #expect(result.title == "Andor")
        #expect(result.detail == "2022")
        #expect(result.kind == .sonarr)
    }

    @Test
    func aggregatesDashboardFromConfiguredServers() async throws {
        let manager = InMemoryServerManager(storedProfiles: [Fixtures.sonarrServer, Fixtures.radarrServer])
        let repository = DashboardRepository(serverManager: manager, healthChecker: ServiceHealthChecker())

        let snapshot = try await repository.loadDashboard()

        #expect(snapshot.queueCount == 2)
        #expect(snapshot.health.count == 2)
        #expect(snapshot.recentItems.count == 2)
    }
}
