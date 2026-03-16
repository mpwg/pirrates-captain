import PirratesCore
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
                        serverRow(server)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = viewModel.servers.firstIndex(where: { $0.id == server.id }) {
                                        viewModel.deleteServers(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
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

    @ViewBuilder
    private func serverRow(_ server: ServerProfile) -> some View {
        let validation = viewModel.validationState(for: server)

        VStack(alignment: .leading, spacing: 10) {
            Button {
                viewModel.presentEditServer(server)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .foregroundStyle(.primary)

                            Text(server.baseURL.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {
                            Text(server.kind.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(statusTitle(for: validation))
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusTint(for: validation).opacity(0.15))
                                .foregroundStyle(statusTint(for: validation))
                                .clipShape(Capsule())
                        }
                    }

                    Text(validation.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button(server.isEnabled ? "Disable" : "Enable") {
                    Task {
                        await viewModel.toggleServerEnabled(server)
                    }
                }
                .buttonStyle(.bordered)

                Button("Re-check") {
                    Task {
                        await viewModel.revalidateServer(server)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!server.isEnabled || validation.kind == .checking)

                Spacer()
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Color.clear)
    }

    private func statusTitle(for validation: ServersViewModel.ValidationState) -> String {
        switch validation.kind {
        case .unchecked:
            "Unchecked"
        case .checking:
            "Checking"
        case .healthy:
            "Connected"
        case .disabled:
            "Disabled"
        case .unsupported:
            "MVP Later"
        case .offline:
            "Offline"
        case .unauthorized:
            "Auth Failed"
        case .degraded:
            "Needs Attention"
        }
    }

    private func statusTint(for validation: ServersViewModel.ValidationState) -> Color {
        switch validation.kind {
        case .healthy:
            AppTheme.success
        case .checking, .unchecked, .unsupported:
            AppTheme.accent
        case .disabled, .degraded:
            AppTheme.warning
        case .offline, .unauthorized:
            .red
        }
    }
}
