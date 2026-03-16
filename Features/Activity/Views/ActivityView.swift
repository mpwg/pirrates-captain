import PirratesCore
import PirratesDesignSystem
import SwiftUI

struct ActivityView: View {
    @Bindable var viewModel: ActivityViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                switch viewModel.state {
                case .idle, .loading:
                    ProgressView().tint(.white)
                case let .failed(error):
                    StatusCard(title: "Activity unavailable", subtitle: error.localizedDescription, tint: AppTheme.warning)
                case let .loaded(items):
                    if items.isEmpty {
                        StatusCard(
                            title: "No activity yet",
                            subtitle: "Connect Sonarr or Radarr to view queue progress and recent history."
                        )
                    } else {
                        ForEach(items) { item in
                            activityCard(for: item)
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
            await viewModel.load()
        }
    }

    private func activityCard(for item: ActivityItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.white)

            Text("\(item.category.displayName) • \(item.service.displayName) • \(item.serverName)")
                .font(.caption)
                .foregroundStyle(tint(for: item).opacity(0.9))

            Text(item.detail)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))

            if let progress = item.progress {
                ProgressView(value: progress)
                    .tint(tint(for: item))
            }

            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint(for: item).opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func tint(for item: ActivityItem) -> Color {
        switch item.category {
        case .queue:
            item.service == .sonarr ? AppTheme.accent : AppTheme.warning
        case .history:
            AppTheme.success
        }
    }
}
