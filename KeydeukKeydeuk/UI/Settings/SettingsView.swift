import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trigger Settings")
                .font(.headline)

            Picker(
                "Global Hotkey",
                selection: Binding(
                    get: { viewModel.selectedHotkeyPresetID },
                    set: { viewModel.selectHotkeyPreset(id: $0) }
                )
            ) {
                ForEach(viewModel.hotkeyPresets) { preset in
                    Text(preset.title).tag(preset.id)
                }
            }
            .pickerStyle(.menu)

            Toggle(
                "Hide on ESC",
                isOn: Binding(
                    get: { viewModel.autoHideOnEsc },
                    set: { viewModel.setAutoHideOnEsc($0) }
                )
            )

            Toggle(
                "Hide on App Switch",
                isOn: Binding(
                    get: { viewModel.autoHideOnAppSwitch },
                    set: { viewModel.setAutoHideOnAppSwitch($0) }
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
