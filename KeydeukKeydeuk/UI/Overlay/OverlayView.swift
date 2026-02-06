import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Focused App")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.appName)
                    .font(.headline)
                Text(viewModel.appBundleID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            TextField("Search shortcuts", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            if viewModel.filteredShortcuts.isEmpty {
                ContentUnavailableView(
                    "No shortcuts yet",
                    systemImage: "keyboard",
                    description: Text("Catalog data for this app is not added yet.")
                )
                .frame(minHeight: 280)
            } else {
                List(viewModel.filteredShortcuts) { shortcut in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(shortcut.title)
                            if let section = shortcut.section {
                                Text(section)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(shortcut.keys)
                            .font(.body.monospaced())
                    }
                }
                .frame(minHeight: 280)
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
