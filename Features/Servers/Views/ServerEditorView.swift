import PirratesCore
import SwiftUI

struct ServerEditorView: View {
    @Bindable var viewModel: ServersViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("Name", text: $viewModel.draft.name)

                    Picker("Service", selection: $viewModel.draft.kind) {
                        ForEach(ServiceKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }

                    TextField("Base URL", text: $viewModel.draft.baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    SecureField("API Key", text: $viewModel.draft.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Options") {
                    Toggle("Enable server", isOn: $viewModel.draft.isEnabled)
                    Toggle("Allow insecure HTTP", isOn: $viewModel.draft.allowsInsecureConnections)
                }

                if !viewModel.draft.validationMessages.isEmpty {
                    Section("Validation") {
                        ForEach(viewModel.draft.validationMessages, id: \.self) { message in
                            Text(message)
                                .foregroundStyle(message.contains("not implemented in the MVP") ? Color.secondary : .red)
                        }
                    }
                }

                if let editorError = viewModel.editorErrorMessage {
                    Section {
                        Text(editorError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.draft.isEditing ? "Edit Server" : "Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveDraft() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.draft.validationMessages.contains { !$0.contains("not implemented in the MVP") })
                }
            }
        }
    }
}
