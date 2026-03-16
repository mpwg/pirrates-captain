import Observation
import PirratesCore
import PirratesDesignSystem
import PirratesIntegrations
import SwiftData
import SwiftUI

@MainActor
final class CompositionRoot {
    let modelContainer: ModelContainer
    let serverManager: any ServerManaging
    let dashboardProvider: any DashboardProviding
    let discoverProvider: any DiscoverProviding
    let libraryProvider: any LibraryProviding
    let activityProvider: any ActivityProviding
    let healthChecker: any HealthChecking
    let serverValidator: any ServerConnectionValidating

    private init(
        modelContainer: ModelContainer,
        serverManager: any ServerManaging,
        dashboardProvider: any DashboardProviding,
        discoverProvider: any DiscoverProviding,
        libraryProvider: any LibraryProviding,
        activityProvider: any ActivityProviding,
        healthChecker: any HealthChecking,
        serverValidator: any ServerConnectionValidating
    ) {
        self.modelContainer = modelContainer
        self.serverManager = serverManager
        self.dashboardProvider = dashboardProvider
        self.discoverProvider = discoverProvider
        self.libraryProvider = libraryProvider
        self.activityProvider = activityProvider
        self.healthChecker = healthChecker
        self.serverValidator = serverValidator
    }

    static func bootstrap() -> CompositionRoot {
        let modelContainer = (try? AppModelContainer.make()) ?? {
            do {
                return try AppModelContainer.make(inMemory: true)
            } catch {
                fatalError("Unable to create model container: \(error)")
            }
        }()

        let secretStore = KeychainSecretStore(service: "com.matthiaswallnergehri.pirrates-captain")
        let serverManager = LocalServerManager(
            modelContext: modelContainer.mainContext,
            secretStore: secretStore
        )
        let serverValidator = ArrServerConnectionValidator()
        let healthChecker = ServiceHealthChecker(serverManager: serverManager, validator: serverValidator)

        return CompositionRoot(
            modelContainer: modelContainer,
            serverManager: serverManager,
            dashboardProvider: DashboardRepository(serverManager: serverManager, healthChecker: healthChecker),
            discoverProvider: DiscoverRepository(serverManager: serverManager),
            libraryProvider: LibraryRepository(serverManager: serverManager),
            activityProvider: ActivityRepository(serverManager: serverManager),
            healthChecker: healthChecker,
            serverValidator: serverValidator
        )
    }
}
