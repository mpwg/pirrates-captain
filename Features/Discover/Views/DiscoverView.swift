import PirratesDesignSystem
import SwiftUI

struct DiscoverView: View {
    @Bindable var viewModel: DiscoverViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Discover")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            TextField("Search movies, shows, music", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            Button("Search") {
                Task {
                    await viewModel.search()
                }
            }
            .buttonStyle(.borderedProminent)

            content

            Spacer()
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            StatusCard(title: "Ready", subtitle: "Enter a query to search configured services.")
        case .loading:
            ProgressView().tint(.white)
        case let .failed(error):
            StatusCard(title: "Search failed", subtitle: error.localizedDescription, tint: AppTheme.warning)
        case let .loaded(results):
            List(results) { result in
                VStack(alignment: .leading) {
                    Text(result.title)
                    Text(result.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
}
