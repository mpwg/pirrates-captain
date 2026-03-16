import Observation
import PirratesCore

@MainActor
@Observable
final class DashboardViewModel {
    var state: LoadPhase<DashboardSnapshot> = .idle

    private let dashboardProvider: any DashboardProviding
    private let healthChecker: any HealthChecking
    private let serverManager: any ServerManaging

    init(
        dashboardProvider: any DashboardProviding,
        healthChecker: any HealthChecking,
        serverManager: any ServerManaging
    ) {
        self.dashboardProvider = dashboardProvider
        self.healthChecker = healthChecker
        self.serverManager = serverManager
    }

    func load() async {
        state = .loading

        do {
            let snapshot = try await dashboardProvider.loadDashboard()
            state = .loaded(snapshot)
        } catch {
            state = .failed(ErrorMapper.map(error))
        }
    }

    func refreshHealth() async {
        do {
            let profiles = try serverManager.profiles()
            let health = await healthChecker.checkHealth(for: profiles.filter(\.isEnabled))

            if case let .loaded(snapshot) = state {
                state = .loaded(
                    DashboardSnapshot(
                        queueCount: snapshot.queueCount,
                        recentItems: snapshot.recentItems,
                        upcomingItems: snapshot.upcomingItems,
                        health: health
                    )
                )
            }
        } catch {
            state = .failed(ErrorMapper.map(error))
        }
    }
}
