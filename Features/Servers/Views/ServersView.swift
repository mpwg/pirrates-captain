import PirratesDesignSystem
import SwiftUI

struct ServersView: View {
    @Bindable var viewModel: ServersViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Servers")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button("Add Sample") {
                    viewModel.addSampleServer()
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage = viewModel.errorMessage {
                StatusCard(title: "Server storage error", subtitle: errorMessage, tint: AppTheme.warning)
            }

            List {
                ForEach(viewModel.servers) { server in
                    VStack(alignment: .leading) {
                        Text(server.name)
                        Text(server.baseURL.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: viewModel.deleteServers)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            Spacer()
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
    }
}
