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
                        if viewModel.saveDraft() {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
