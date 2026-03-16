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
                        dashboardSection(
                            title: "Recent releases",
                            items: snapshot.recentItems,
                            emptyState: "No recent activity reported in the last 7 days."
                        )
                        dashboardSection(
                            title: "Upcoming",
                            items: snapshot.upcomingItems,
                            emptyState: "No scheduled releases in the next 14 days."
                        )

                        ForEach(snapshot.health) { health in
                            StatusCard(
                                title: "\(health.serverName) (\(health.service.displayName))",
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

    @ViewBuilder
    private func dashboardSection(title: String, items: [DashboardItem], emptyState: String) -> some View {
        if items.isEmpty {
            StatusCard(title: title, subtitle: emptyState)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                ForEach(items) { item in
                    StatusCard(
                        title: item.title,
                        subtitle: "\(item.detail) • \(item.serverName) • \(item.date.formatted(date: .abbreviated, time: .omitted))",
                        tint: item.service == .sonarr ? AppTheme.accent : AppTheme.warning
                    )
                }
            }
        }
    }
}
