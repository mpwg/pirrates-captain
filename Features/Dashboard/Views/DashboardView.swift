import PirratesCore
import PirratesDesignSystem
import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Dashboard")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                        .tint(.white)
                case let .failed(error):
                    StatusCard(title: "Unable to load dashboard", subtitle: error.localizedDescription, tint: AppTheme.warning)
                case let .loaded(snapshot):
                    if snapshot.health.isEmpty {
                        StatusCard(
                            title: "No servers connected",
                            subtitle: "Open the Servers tab to configure Sonarr, Radarr, Lidarr, Prowlarr, or SABnzbd."
                        )
                    } else {
                        StatusCard(title: "Queue", subtitle: "\(snapshot.queueCount) active items")
                        StatusCard(title: "Recent items", subtitle: "\(snapshot.recentItems.count) sources reporting")
                        StatusCard(title: "Upcoming items", subtitle: "\(snapshot.upcomingItems.count) sources reporting")

                        ForEach(snapshot.health) { health in
                            StatusCard(
                                title: health.service.displayName,
                                subtitle: health.message,
                                tint: tint(for: health.status)
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refreshHealth()
        }
    }

    private func tint(for status: ServiceHealth.Status) -> Color {
        switch status {
        case .healthy:
            AppTheme.success
        case .degraded:
            AppTheme.warning
        case .offline, .unauthorized:
            .red
        }
    }
}
