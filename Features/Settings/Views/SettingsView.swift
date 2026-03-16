import PirratesDesignSystem
import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            StatusCard(title: "Version", subtitle: viewModel.appVersion)

            Toggle("Diagnostics enabled", isOn: $viewModel.diagnosticsEnabled)
                .toggleStyle(.switch)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
    }
}
