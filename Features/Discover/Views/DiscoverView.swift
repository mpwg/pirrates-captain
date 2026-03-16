import PirratesCore
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
        .sheet(item: $viewModel.selectedResult) { result in
            NavigationStack {
                addSheet(for: result)
            }
            .presentationDetents([.medium, .large])
        }
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
                Button {
                    viewModel.beginAddFlow(for: result)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.title)
                            .foregroundStyle(.primary)
                        Text("\(result.detail) • \(result.serverName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }

    @ViewBuilder
    private func addSheet(for result: SearchResult) -> some View {
        if viewModel.isPreparingAdd {
            VStack(spacing: 16) {
                ProgressView()
                Text("Loading options for \(result.serverName)…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else if let addContext = viewModel.addContext {
            DiscoverAddSheet(
                result: result,
                context: addContext,
                isAdding: viewModel.isAdding,
                addError: viewModel.addError,
                onCancel: { viewModel.completeAddFlow() },
                onAdd: { configuration in
                    Task {
                        await viewModel.submitAdd(using: configuration)
                    }
                }
            )
        } else if let addError = viewModel.addError {
            VStack(spacing: 16) {
                StatusCard(title: "Unable to prepare add flow", subtitle: addError.localizedDescription, tint: AppTheme.warning)
                Button("Close") {
                    viewModel.completeAddFlow()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

private struct DiscoverAddSheet: View {
    let result: SearchResult
    let context: DiscoverAddContext
    let isAdding: Bool
    let addError: AppError?
    let onCancel: () -> Void
    let onAdd: (DiscoverAddConfiguration) -> Void

    @State private var configuration: DiscoverAddConfiguration

    init(
        result: SearchResult,
        context: DiscoverAddContext,
        isAdding: Bool,
        addError: AppError?,
        onCancel: @escaping () -> Void,
        onAdd: @escaping (DiscoverAddConfiguration) -> Void
    ) {
        self.result = result
        self.context = context
        self.isAdding = isAdding
        self.addError = addError
        self.onCancel = onCancel
        self.onAdd = onAdd
        _configuration = State(initialValue: context.defaultConfiguration)
    }

    var body: some View {
        Form {
            Section("Destination") {
                Text(context.serverName)
                optionPicker("Root Folder", selection: $configuration.rootFolderPath, options: context.rootFolders)
                qualityProfilePicker
            }

            Section("Monitoring") {
                optionPicker("Monitor", selection: $configuration.monitor, options: context.monitorOptions)

                if context.service == .sonarr {
                    optionPicker("Series Type", selection: $configuration.seriesType, options: context.seriesTypeOptions)
                    Toggle("Season Folder", isOn: $configuration.seasonFolder)
                    Toggle("Search for Missing Episodes", isOn: $configuration.searchForMissingEpisodes)
                    Toggle("Search for Cutoff Unmet Episodes", isOn: $configuration.searchForCutoffUnmetEpisodes)
                } else if context.service == .radarr {
                    optionPicker("Minimum Availability", selection: $configuration.minimumAvailability, options: context.minimumAvailabilityOptions)
                    Toggle("Start Search for Movie", isOn: $configuration.searchForMovie)
                }
            }

            if let addError {
                Section {
                    StatusCard(title: "Add failed", subtitle: addError.localizedDescription, tint: AppTheme.warning)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(result.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isAdding ? "Adding…" : "Add") {
                    onAdd(configuration)
                }
                .disabled(isAdding || configuration.rootFolderPath.isEmpty || configuration.qualityProfileID == 0)
            }
        }
    }

    private var qualityProfilePicker: some View {
        Picker("Quality Profile", selection: Binding(
            get: { String(configuration.qualityProfileID) },
            set: { configuration.qualityProfileID = Int($0) ?? 0 }
        )) {
            ForEach(context.qualityProfiles) { option in
                Text(option.title).tag(option.id)
            }
        }
    }

    private func optionPicker(_ title: String, selection: Binding<String>, options: [DiscoverOption]) -> some View {
        Picker(title, selection: selection) {
            ForEach(options) { option in
                Text(option.title).tag(option.id)
            }
        }
    }
}
