import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppContainer {
    let overlayViewModel: OverlayViewModel

    private let orchestrator: AppOrchestrator
    private let statusBarController: StatusBarController
    private let overlayPanelController: OverlayPanelController
    private var settingsWindowController: NSWindowController?
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let preferencesStore = UserDefaultsPreferencesStore()
        let shortcutRepository = JSONCatalogRepository()

        let overlayState = OverlaySceneState()

        let permissionChecker = AXPermissionChecker()
        let permissionGuide = SystemPermissionGuide()
        let appContextProvider = NSWorkspaceAppContextProvider()
        let overlayPresenter = OverlayWindowHost(state: overlayState)
        let eventSource = NSEventGlobalHotkeySource()

        let activationPolicy = DefaultActivationPolicy()

        let evaluateActivation = EvaluateActivationUseCase(
            policy: activationPolicy,
            preferencesStore: preferencesStore
        )
        let loadShortcuts = LoadShortcutsForAppUseCase(repository: shortcutRepository)
        let loadPreferences = LoadPreferencesUseCase(preferencesStore: preferencesStore)
        let getAccessibilityPermissionState = GetAccessibilityPermissionStateUseCase(permissionChecker: permissionChecker)
        let requestAccessibilityPermission = RequestAccessibilityPermissionUseCase(permissionGuide: permissionGuide)
        let showOverlay = ShowOverlayForCurrentAppUseCase(
            permissionChecker: permissionChecker,
            appContextProvider: appContextProvider,
            loadShortcuts: loadShortcuts,
            presenter: overlayPresenter
        )
        let hideOverlay = HideOverlayUseCase(presenter: overlayPresenter)
        let updatePreferences = UpdatePreferencesUseCase(preferencesStore: preferencesStore)
        let openAccessibilitySettings = OpenAccessibilitySettingsUseCase(permissionGuide: permissionGuide)

        self.overlayViewModel = OverlayViewModel(
            state: overlayState,
            loadPreferences: loadPreferences,
            getAccessibilityPermissionState: getAccessibilityPermissionState,
            requestAccessibilityPermission: requestAccessibilityPermission,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            updatePreferencesUseCase: updatePreferences,
            openAccessibilitySettings: openAccessibilitySettings
        )
        self.overlayPanelController = OverlayPanelController(state: overlayState, viewModel: overlayViewModel)

        self.orchestrator = AppOrchestrator(
            eventSource: eventSource,
            evaluateActivation: evaluateActivation,
            showOverlay: showOverlay,
            hideOverlay: hideOverlay,
            onShowResult: { [weak overlayViewModel] result in
                overlayViewModel?.handle(showResult: result)
            }
        )

        self.statusBarController = StatusBarController()
        self.statusBarController.onPrimaryClick = { [weak self, weak overlayViewModel] in
            guard let self else { return }
            guard let overlayViewModel else { return }
            Task { @MainActor in
                await overlayViewModel.requestShow()
                if overlayViewModel.isVisible {
                    return
                }
                NSApp.activate(ignoringOtherApps: true)
                if overlayViewModel.needsOnboarding {
                    self.bringMainWindowToFront()
                }
            }
        }
        self.statusBarController.onSettingsClick = { [weak self, weak overlayViewModel] in
            guard let self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.presentSettingsWindow()
            if self.settingsWindowController == nil {
                overlayViewModel?.showInfoMessage("Unable to open Settings window.")
            }
        }

        overlayViewModel.$needsOnboarding
            .removeDuplicates()
            .sink { [weak self] needsOnboarding in
                self?.applyAppPresentation(needsOnboarding: needsOnboarding)
            }
            .store(in: &cancellables)
    }

    func start() {
        overlayViewModel.refreshPreferences()
        overlayPanelController.start()
        statusBarController.start()
        orchestrator.start()
        applyAppPresentation(needsOnboarding: overlayViewModel.needsOnboarding)
    }

    private func applyAppPresentation(needsOnboarding: Bool) {
        if needsOnboarding {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            bringMainWindowToFront()
            return
        }

        NSApp.setActivationPolicy(.accessory)
        overlayPanelController.hide()
        NSApp.windows.forEach { $0.orderOut(nil) }
    }

    private func bringMainWindowToFront() {
        if let window = NSApp.windows.first(where: { $0.title == "Onboarding" || $0.title == "KeydeukKeydeuk" }) {
            window.makeKeyAndOrderFront(nil)
            return
        }
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    private func presentSettingsWindow() {
        if let existingWindow = settingsWindowController?.window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let host = NSHostingController(rootView: SettingsWindowView(viewModel: overlayViewModel))
        let window = NSWindow(contentViewController: host)
        window.title = "KeydeukKeydeuk Settings"
        window.styleMask = NSWindow.StyleMask([.titled, .closable, .miniaturizable])
        window.setContentSize(NSSize(width: 560, height: 320))
        window.center()
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
        settingsWindowController = controller
    }
}
