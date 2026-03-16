import Foundation
import Testing
import PirratesCore
@testable import PirratesIntegrations

@MainActor
struct MappingAndRepositoryTests {
    @Test
    func mapsSonarrSeriesIntoSearchResult() {
        let dto = SonarrSeriesDTO(title: "Andor", year: 2022, overview: "Rebellion", tvdbId: 123)
        let result = SonarrSeriesMapper.map(dto, profile: Fixtures.sonarrServer)

        #expect(result?.title == "Andor")
        #expect(result?.detail == "2022")
        #expect(result?.kind == .sonarr)
        #expect(result?.serverID == Fixtures.sonarrServer.id)
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
                return makeJSONResponse(statusCode: 200, body: #"[{"title":"Andor","year":2022,"overview":"Rebellion","tvdbId":100}]"#, url: request.url!)
            case "/api/v3/movie/lookup":
                return makeJSONResponse(statusCode: 200, body: #"[{"title":"Dune","year":2021,"overview":"Spice","tmdbId":200}]"#, url: request.url!)
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let repository = DiscoverRepository(serverManager: manager, httpClient: httpClient)
        let results = try await repository.search(query: "test")

        #expect(results.count == 2)
        #expect(results.contains { $0.title == "Andor" && $0.kind == .sonarr && $0.serverName == Fixtures.sonarrServer.name })
        #expect(results.contains { $0.title == "Dune" && $0.kind == .radarr && $0.serverName == Fixtures.radarrServer.name })
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

    @Test
    func preparesSonarrAddContext() async throws {
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.sonarrServer],
            secrets: [Fixtures.sonarrServer.id: "sonarr-key"]
        )
        let result = SearchResult(
            title: "Andor",
            detail: "2022",
            overview: "Rebellion",
            kind: .sonarr,
            serverID: Fixtures.sonarrServer.id,
            serverName: Fixtures.sonarrServer.name,
            addTarget: .sonarr(tvdbID: 100)
        )
        let httpClient = MockHTTPClient { request in
            switch request.url?.path {
            case "/api/v3/rootfolder":
                return makeJSONResponse(statusCode: 200, body: #"[{"id":1,"path":"/tv","accessible":true}]"#, url: request.url!)
            case "/api/v3/qualityprofile":
                return makeJSONResponse(statusCode: 200, body: #"[{"id":7,"name":"HD-1080p"}]"#, url: request.url!)
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let repository = DiscoverRepository(serverManager: manager, httpClient: httpClient)

        let context = try await repository.prepareAdd(for: result)

        #expect(context.service == .sonarr)
        #expect(context.rootFolders.first?.id == "/tv")
        #expect(context.qualityProfiles.first?.id == "7")
        #expect(context.defaultConfiguration.monitor == "all")
    }

    @Test
    func addsMovieToRadarr() async throws {
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.radarrServer],
            secrets: [Fixtures.radarrServer.id: "radarr-key"]
        )
        let result = SearchResult(
            title: "Dune",
            detail: "2021",
            overview: "Spice",
            kind: .radarr,
            serverID: Fixtures.radarrServer.id,
            serverName: Fixtures.radarrServer.name,
            addTarget: .radarr(tmdbID: 200)
        )
        let httpClient = MockHTTPClient { request in
            #expect(request.url?.path == "/api/v3/movie")
            #expect(request.httpMethod == "POST")
            let body = try #require(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            #expect(json?["tmdbId"] as? Int == 200)
            #expect(json?["rootFolderPath"] as? String == "/movies")
            #expect(json?["monitor"] as? String == "movieOnly")
            return makeJSONResponse(statusCode: 201, body: #"{"title":"Dune","year":2021,"overview":"Spice","tmdbId":200}"#, url: request.url!)
        }
        let repository = DiscoverRepository(serverManager: manager, httpClient: httpClient)

        try await repository.add(
            result: result,
            configuration: DiscoverAddConfiguration(
                rootFolderPath: "/movies",
                qualityProfileID: 5,
                monitor: "movieOnly",
                seriesType: "standard",
                minimumAvailability: "released",
                seasonFolder: false,
                searchForMissingEpisodes: false,
                searchForCutoffUnmetEpisodes: false,
                searchForMovie: true
            )
        )
    }

    @Test
    func loadsLibraryAcrossSupportedServices() async throws {
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.sonarrServer, Fixtures.radarrServer],
            secrets: [
                Fixtures.sonarrServer.id: "sonarr-key",
                Fixtures.radarrServer.id: "radarr-key",
            ]
        )
        let httpClient = MockHTTPClient { request in
            switch request.url?.path {
            case "/api/v3/series":
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"[{"title":"Andor","year":2022,"overview":"Rebellion","tvdbId":100,"status":"continuing","network":"Disney+"}]"#,
                    url: request.url!
                )
            case "/api/v3/movie":
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"[{"title":"Dune","year":2021,"overview":"Spice","tmdbId":200,"status":"released","studio":"Legendary"}]"#,
                    url: request.url!
                )
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let repository = LibraryRepository(serverManager: manager, httpClient: httpClient)

        let items = try await repository.loadLibrary()

        #expect(items.count == 2)
        #expect(items.contains { $0.title == "Andor" && $0.kind == .sonarr && $0.serverName == Fixtures.sonarrServer.name })
        #expect(items.contains { $0.title == "Dune" && $0.kind == .radarr && $0.serverName == Fixtures.radarrServer.name })
    }

    @Test
    func loadsActivityAcrossSupportedServices() async throws {
        let manager = InMemoryServerManager(
            storedProfiles: [Fixtures.sonarrServer, Fixtures.radarrServer],
            secrets: [
                Fixtures.sonarrServer.id: "sonarr-key",
                Fixtures.radarrServer.id: "radarr-key",
            ]
        )
        let httpClient = MockHTTPClient { request in
            switch request.url?.path {
            case "/api/v3/queue":
                if request.url?.host == "sonarr.local" {
                    return makeJSONResponse(
                        statusCode: 200,
                        body: #"{"records":[{"id":1,"title":"Chapter 1","status":"downloading","trackedDownloadStatus":"downloading","size":1000,"sizeleft":250,"timeleft":"00:15:00","estimatedCompletionTime":"2026-03-21T10:15:00Z","series":{"title":"Andor"},"episode":{"title":"Chapter 1"}}]}"#,
                        url: request.url!
                    )
                }
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"{"records":[{"id":2,"title":"Dune","status":"queued","trackedDownloadState":"downloading","size":2000,"sizeleft":500,"timeleft":"00:30:00","estimatedCompletionTime":"2026-03-21T11:00:00Z","movie":{"title":"Dune"}}]}"#,
                    url: request.url!
                )
            case "/api/v3/history":
                if request.url?.host == "sonarr.local" {
                    return makeJSONResponse(
                        statusCode: 200,
                        body: #"{"records":[{"id":11,"sourceTitle":"Chapter 1","eventType":"downloadFolderImported","date":"2026-03-20T12:00:00Z","series":{"title":"Andor"},"episode":{"title":"Chapter 1"}}]}"#,
                        url: request.url!
                    )
                }
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"{"records":[{"id":12,"sourceTitle":"Dune","eventType":"movieFileDeleted","date":"2026-03-20T09:00:00Z","movie":{"title":"Dune"}}]}"#,
                    url: request.url!
                )
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let repository = ActivityRepository(serverManager: manager, httpClient: httpClient)

        let items = try await repository.loadActivity()

        #expect(items.count == 4)
        #expect(items.first?.title == "Dune")
        #expect(items.contains { $0.title == "Andor" && $0.category == .queue && $0.service == .sonarr && $0.progress == 0.75 })
        #expect(items.contains { $0.title == "Dune" && $0.category == .history && $0.service == .radarr && $0.progress == nil })
    }

    @Test
    func activityToleratesPartialServiceFailures() async throws {
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
            case "/api/v3/queue":
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"{"records":[{"id":1,"title":"Chapter 1","status":"downloading","size":1000,"sizeleft":500,"estimatedCompletionTime":"2026-03-21T10:15:00Z","series":{"title":"Andor"}}]}"#,
                    url: request.url!
                )
            case "/api/v3/history":
                return makeJSONResponse(
                    statusCode: 200,
                    body: #"{"records":[{"id":11,"sourceTitle":"Chapter 1","eventType":"grabbed","date":"2026-03-20T12:00:00Z","series":{"title":"Andor"}}]}"#,
                    url: request.url!
                )
            default:
                Issue.record("Unexpected path \(request.url?.path ?? "nil")")
                return makeJSONResponse(statusCode: 404, body: #"{}"#, url: request.url!)
            }
        }
        let repository = ActivityRepository(serverManager: manager, httpClient: httpClient)

        let items = try await repository.loadActivity()

        #expect(items.count == 2)
        #expect(items.allSatisfy { $0.service == .sonarr })
    }
}
