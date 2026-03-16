import PirratesDesignSystem
import SwiftUI

struct RootShellView: View {
    @State private var dashboardViewModel: DashboardViewModel
    @State private var discoverViewModel: DiscoverViewModel
    @State private var libraryViewModel: LibraryViewModel
    @State private var activityViewModel: ActivityViewModel
    @State private var serversViewModel: ServersViewModel
    @State private var settingsViewModel = SettingsViewModel()

    init(root: CompositionRoot) {
        _dashboardViewModel = State(initialValue: DashboardViewModel(
            dashboardProvider: root.dashboardProvider,
            healthChecker: root.healthChecker,
            serverManager: root.serverManager
        ))
        _discoverViewModel = State(initialValue: DiscoverViewModel(discoverProvider: root.discoverProvider))
        _libraryViewModel = State(initialValue: LibraryViewModel(libraryProvider: root.libraryProvider))
        _activityViewModel = State(initialValue: ActivityViewModel(activityProvider: root.activityProvider))
        _serversViewModel = State(initialValue: ServersViewModel(serverManager: root.serverManager))
    }

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(viewModel: dashboardViewModel)
            }
            .tabItem {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent")
            }

            NavigationStack {
                DiscoverView(viewModel: discoverViewModel)
            }
            .tabItem {
                Label("Discover", systemImage: "magnifyingglass")
            }

            NavigationStack {
                LibraryView(viewModel: libraryViewModel)
            }
            .tabItem {
                Label("Library", systemImage: "rectangle.stack")
            }

            NavigationStack {
                ActivityView(viewModel: activityViewModel)
            }
            .tabItem {
                Label("Activity", systemImage: "arrow.down.circle")
            }

            NavigationStack {
                ServersView(viewModel: serversViewModel)
            }
            .tabItem {
                Label("Servers", systemImage: "server.rack")
            }

            NavigationStack {
                SettingsView(viewModel: settingsViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(AppTheme.accent)
    }
}
