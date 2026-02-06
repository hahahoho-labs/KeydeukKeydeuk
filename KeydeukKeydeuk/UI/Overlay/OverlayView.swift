import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Search shortcuts", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            Text(viewModel.appName)
                .font(.headline)

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
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
