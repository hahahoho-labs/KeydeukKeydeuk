import AppKit
import SwiftUI

// MARK: - Section Grouping

private struct ShortcutGroup: Identifiable {
    let id: String
    let title: String
    let shortcuts: [Shortcut]
}

// MARK: - Overlay View

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    private var groupedShortcuts: [ShortcutGroup] {
        let shortcuts = viewModel.filteredShortcuts
        let grouped = Dictionary(grouping: shortcuts) { $0.section ?? "General" }
        return grouped
            .map { ShortcutGroup(id: $0.key, title: $0.key, shortcuts: $0.value) }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        VStack(spacing: 0) {
            headerBar

            Divider()

            if viewModel.filteredShortcuts.isEmpty {
                emptyState
            } else {
                shortcutGrid
            }

            Divider()

            modifierLegend
        }
        .background(palette.overlayPanelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.overlayPanelBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: palette.overlayShadow, radius: 40, y: 10)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            if let icon = viewModel.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: "app.dashed")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.appName)
                    .font(.headline)
                Text(viewModel.appBundleID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            searchField
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var searchField: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        return HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Search shortcuts…", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.callout)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(palette.overlaySearchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: 220)
    }

    // MARK: - Shortcut Grid

    private var shortcutGrid: some View {
        GeometryReader { proxy in
            let groups = groupedShortcuts
            let minColWidth: CGFloat = 230
            let hPadding: CGFloat = 32
            let colSpacing: CGFloat = 24
            let available = proxy.size.width - hPadding
            let maxCols = max(1, Int((available + colSpacing) / (minColWidth + colSpacing)))
            let colCount = max(1, min(groups.count, maxCols))
            let distributed = Self.distribute(groups, into: colCount)

            ScrollView(.vertical, showsIndicators: true) {
                HStack(alignment: .top, spacing: colSpacing) {
                    ForEach(Array(distributed.enumerated()), id: \.offset) { _, column in
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(column) { group in
                                sectionBlock(group)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, hPadding / 2)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Section Block

    private func sectionBlock(_ group: ShortcutGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                ForEach(group.shortcuts) { shortcut in
                    ShortcutRowView(shortcut: shortcut)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "keyboard")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No shortcuts yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Catalog data for this app is not added yet.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
    }

    // MARK: - Modifier Legend

    private var modifierLegend: some View {
        HStack(spacing: 16) {
            legendPair("⌘", "command")
            legendPair("⌃", "control")
            legendPair("⇧", "shift")
            legendPair("⌥", "option")
            legendPair("⇥", "tab")
            legendPair("⎋", "esc")
            legendPair("↩", "return")
            legendPair("⌫", "delete")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func legendPair(_ symbol: String, _ name: String) -> some View {
        HStack(spacing: 3) {
            Text(symbol)
                .font(.callout.monospaced().weight(.medium))
                .foregroundStyle(.primary.opacity(0.6))
            Text(name)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Column Distribution

    private static func distribute(_ groups: [ShortcutGroup], into count: Int) -> [[ShortcutGroup]] {
        guard count > 0 else { return [] }

        var columns: [[ShortcutGroup]] = Array(repeating: [], count: count)
        var heights: [CGFloat] = Array(repeating: 0, count: count)

        let headerH: CGFloat = 24
        let rowH: CGFloat = 26
        let sectionGap: CGFloat = 18

        for group in groups {
            let h = headerH + CGFloat(group.shortcuts.count) * rowH + sectionGap
            let shortest = heights.enumerated().min(by: { $0.element < $1.element })!.offset
            columns[shortest].append(group)
            heights[shortest] += h
        }

        return columns
    }
}

// MARK: - Shortcut Row

private struct ShortcutRowView: View {
    let shortcut: Shortcut
    @State private var isHovered = false
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        HStack(spacing: 8) {
            Text(shortcut.title)
                .font(.callout)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(shortcut.keys)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.vertical, 2.5)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isHovered ? palette.overlayRowHoverBackground : palette.overlayRowBackground)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
