import PirratesDesignSystem
import SwiftUI

struct ActivityView: View {
    @Bindable var viewModel: ActivityViewModel

    var body: some View {
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
                List(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: item.progress)
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
