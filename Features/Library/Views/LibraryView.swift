import PirratesDesignSystem
import SwiftUI

struct LibraryView: View {
    @Bindable var viewModel: LibraryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            switch viewModel.state {
            case .idle, .loading:
                ProgressView().tint(.white)
            case let .failed(error):
                StatusCard(title: "Library unavailable", subtitle: error.localizedDescription, tint: AppTheme.warning)
            case let .loaded(items):
                if items.isEmpty {
                    StatusCard(
                        title: "No library items yet",
                        subtitle: "Connect Sonarr or Radarr and add media to populate the library."
                    )
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.overview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Text("\(item.kind.displayName) • \(item.serverName)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
    }
}
