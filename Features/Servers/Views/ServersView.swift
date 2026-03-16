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
                Button("Add Server") {
                    viewModel.presentAddServer()
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage = viewModel.errorMessage {
                StatusCard(title: "Server storage error", subtitle: errorMessage, tint: AppTheme.warning)
            }

            if viewModel.servers.isEmpty {
                StatusCard(
                    title: "No servers configured",
                    subtitle: "Add your first Sonarr, Radarr, Lidarr, Prowlarr, or SABnzbd server to begin."
                )
            } else {
                List {
                    ForEach(viewModel.servers) { server in
                        Button {
                            viewModel.presentEditServer(server)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(server.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(server.kind.displayName)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Text(server.baseURL.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !server.isEnabled {
                                    Text("Disabled")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: viewModel.deleteServers)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(isPresented: $viewModel.isPresentingEditor) {
            ServerEditorView(viewModel: viewModel)
        }
    }
}
