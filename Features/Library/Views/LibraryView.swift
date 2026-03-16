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
                List(items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
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
