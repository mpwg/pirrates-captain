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
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.sonarrServer, Fixtures.radarrServer],
            secrets: [
                Fixtures.sonarrServer.id: "sonarr-key",
                Fixtures.radarrServer.id: "radarr-key",
            ]
        )
        let httpClient = MockHTTPClient { request in
            switch request.url?.path {
            case "/api/v3/system/status":
                return makeJSONResponse(statusCode: 200, body: #"{"appName":"Test","version":"1.0"}"#, url: request.url!)
            case "/api/v3/queue":
                return makeJSONResponse(statusCode: 200, body: #"{"totalRecords":1,"records":[{"id":1}]}"#, url: request.url!)
            case "/api/v3/calendar":
                if request.url?.host == "sonarr.local" {
                    return makeJSONResponse(
                        statusCode: 200,
                        body: #"[{"title":"Who Are You?","airDateUtc":"2026-03-20T00:00:00Z","series":{"title":"Severance"}}]"#,
                        url: request.url!
                    )
                }
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"[{"title":"Dune: Part Two","inCinemas":"2026-03-22T00:00:00Z","physicalRelease":null,"digitalRelease":null}]"#,
                    url: request.url!
                )
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let validator = ArrServerConnectionValidator(httpClient: httpClient)
        let repository = DashboardRepository(
            serverManager: manager,
            healthChecker: ServiceHealthChecker(serverManager: manager, validator: validator),
            httpClient: httpClient
        )

        let snapshot = try await repository.loadDashboard()

        #expect(snapshot.queueCount == 2)
        #expect(snapshot.health.count == 2)
        #expect(snapshot.health.contains { $0.serverName == Fixtures.sonarrServer.name && $0.status == .healthy })
        #expect(snapshot.recentItems.count == 2)
        #expect(snapshot.upcomingItems.count == 2)
        #expect(snapshot.recentItems.contains { $0.title == "Severance" && $0.serverName == Fixtures.sonarrServer.name })
        #expect(snapshot.upcomingItems.contains { $0.title == "Dune: Part Two" && $0.serverName == Fixtures.radarrServer.name })
    }

    @Test
    func validatesSonarrConnection() async throws {
        let validator = ArrServerConnectionValidator(
            httpClient: MockHTTPClient { request in
                #expect(request.value(forHTTPHeaderField: "X-Api-Key") == "secret")
                return makeJSONResponse(statusCode: 200, body: #"{"appName":"Sonarr","version":"4.0.0"}"#, url: request.url!)
            }
        )

        try await validator.validateServer(Fixtures.sonarrServer, apiKey: "secret")
    }

    @Test
    func searchesAcrossSupportedServices() async throws {
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.sonarrServer, Fixtures.radarrServer],
            secrets: [
                Fixtures.sonarrServer.id: "sonarr-key",
                Fixtures.radarrServer.id: "radarr-key",
            ]
        )
        let httpClient = MockHTTPClient { request in
            switch request.url?.path {
            case "/api/v3/series/lookup":
                return makeJSONResponse(statusCode: 200, body: #"[{"title":"Andor","year":2022}]"#, url: request.url!)
            case "/api/v3/movie/lookup":
                return makeJSONResponse(statusCode: 200, body: #"[{"title":"Dune","year":2021}]"#, url: request.url!)
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let repository = DiscoverRepository(serverManager: manager, httpClient: httpClient)
        let results = try await repository.search(query: "test")

        #expect(results.count == 2)
        #expect(results.contains { $0.title == "Andor" && $0.kind == .sonarr })
        #expect(results.contains { $0.title == "Dune" && $0.kind == .radarr })
    }

    @Test
    func dashboardToleratesPartialServiceFailures() async throws {
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.sonarrServer, Fixtures.radarrServer],
            secrets: [
                Fixtures.sonarrServer.id: "sonarr-key",
                Fixtures.radarrServer.id: "radarr-key",
            ]
        )
        let httpClient = MockHTTPClient { request in
            if request.url?.host == "radarr.local" {
                throw AppError.unreachableServer
            }

            switch request.url?.path {
            case "/api/v3/system/status":
                return makeJSONResponse(statusCode: 200, body: #"{"appName":"Sonarr","version":"4.0.0"}"#, url: request.url!)
            case "/api/v3/queue":
                return makeJSONResponse(statusCode: 200, body: #"{"totalRecords":2,"records":[{"id":1},{"id":2}]}"#, url: request.url!)
            case "/api/v3/calendar":
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"[{"title":"The We We Are","airDateUtc":"2026-03-19T00:00:00Z","series":{"title":"Severance"}}]"#,
                    url: request.url!
                )
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }

        let validator = ArrServerConnectionValidator(httpClient: httpClient)
        let repository = DashboardRepository(
            serverManager: manager,
            healthChecker: ServiceHealthChecker(serverManager: manager, validator: validator),
            httpClient: httpClient
        )

        let snapshot = try await repository.loadDashboard()

        #expect(snapshot.queueCount == 2)
        #expect(snapshot.health.contains { $0.serverName == Fixtures.radarrServer.name && $0.status == .offline })
        #expect(snapshot.recentItems.count == 1)
        #expect(snapshot.upcomingItems.count == 1)
    }
}
