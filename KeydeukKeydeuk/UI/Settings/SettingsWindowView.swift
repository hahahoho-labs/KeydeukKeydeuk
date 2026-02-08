import AppKit
import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var settingsVM: SettingsViewModel
    @ObservedObject var onboardingVM: OnboardingViewModel
    @ObservedObject var themeModeStore: ThemeModeStore
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case theme = "Theme"
        case help = "Help"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .theme: return "paintbrush"
            case .help: return "questionmark.circle"
            }
        }
    }

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        VStack(spacing: 0) {
            // Tab Bar
            tabBar

            Divider()

            // Tab Content
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Bottom Button Bar
            bottomBar
        }
        .frame(minWidth: 760, minHeight: 560)
        .background(
            palette.overlayBackdrop
                .opacity(appEffectiveColorScheme == .dark ? 0.35 : 0.22)
        )
        .applyTheme(
            mode: themeModeStore.selectedThemeMode,
            preset: themeModeStore.selectedThemePreset
        )
        .onAppear {
            onboardingVM.refreshPermissionState()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func tabButton(for tab: SettingsTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                Text(tab.rawValue)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
            .frame(width: 72, height: 44)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsTab(settingsVM: settingsVM, onboardingVM: onboardingVM)
        case .theme:
            ThemeSettingsTab(settingsVM: settingsVM)
        case .help:
            HelpSettingsTab()
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }

            Spacer()

            Button("Cancel") {
                closeWindow()
            }

            Button("OK") {
                closeWindow()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}
