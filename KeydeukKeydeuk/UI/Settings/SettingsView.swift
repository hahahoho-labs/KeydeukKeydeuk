import AppKit
import SwiftUI

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject var settingsVM: SettingsViewModel
    @ObservedObject var onboardingVM: OnboardingViewModel
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let error = settingsVM.errorMessage {
                    errorBanner(error)
                }
                activationSection
                behaviorSection
                permissionSection
            }
            .padding(20)
        }
        .onDisappear {
            settingsVM.cancelCustomHotkeyCapture()
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
            Spacer()
            Button {
                settingsVM.dismissError()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(palette.settingsErrorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Activation

    private var activationSection: some View {
        SettingsSection(title: "Activation") {
            Picker(
                "Default Trigger",
                selection: Binding(
                    get: {
                        settingsVM.selectedTriggerType == .commandDoubleTap
                            ? .commandDoubleTap
                            : .holdCommand
                    },
                    set: { settingsVM.setTriggerType($0) }
                )
            ) {
                Text("Hold ⌘ Command").tag(Preferences.Trigger.holdCommand)
                Text("Double-tap ⌘ Command").tag(Preferences.Trigger.commandDoubleTap)
            }
            .pickerStyle(.menu)

            if settingsVM.selectedTriggerType == .holdCommand {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Hold Duration")
                        Spacer()
                        Text("\(settingsVM.holdDuration, specifier: "%.1f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { settingsVM.holdDuration },
                            set: { settingsVM.setHoldDuration($0) }
                        ),
                        in: 0.3...3.0,
                        step: 0.1
                    )
                }
            }

            // NOTE: custom shortcut feature is temporarily disabled.
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        SettingsSection(title: "Behavior") {
            Toggle(
                "Hide on ESC",
                isOn: Binding(
                    get: { settingsVM.autoHideOnEsc },
                    set: { settingsVM.setAutoHideOnEsc($0) }
                )
            )

            Toggle(
                "Hide on App Switch",
                isOn: Binding(
                    get: { settingsVM.autoHideOnAppSwitch },
                    set: { settingsVM.setAutoHideOnAppSwitch($0) }
                )
            )
        }
    }

    // MARK: - Permission

    private var permissionSection: some View {
        SettingsSection(title: "Permissions") {
            HStack {
                Text("Accessibility")
                Spacer()
                permissionBadge

                Button {
                    onboardingVM.refreshPermissionState()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Refresh permission status")
            }

            if onboardingVM.permissionState != .granted {
                Text("Overlay requires Accessibility permission to read menu shortcuts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Accessibility Settings") {
                    onboardingVM.openAccessibilityPreferences()
                }

                if let hint = onboardingVM.permissionHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var permissionBadge: some View {
        switch onboardingVM.permissionState {
        case .granted:
            Label("Granted", systemImage: "checkmark.circle.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.green)
        case .denied:
            Label("Denied", systemImage: "xmark.circle.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.red)
        case .notDetermined:
            Label("Not Determined", systemImage: "questionmark.circle.fill")
                .font(.callout.weight(.medium))
                .foregroundStyle(.orange)
        }
    }
}

// MARK: - Theme Tab

struct ThemeSettingsTab: View {
    @ObservedObject var settingsVM: SettingsViewModel

    private let defaultThemes: [Preferences.Theme] = [.system, .light, .dark]
    private let customThemes: [Preferences.Theme] = [.graphite, .warmPaper, .nordMist, .highContrast]

    private var selectedTheme: Preferences.Theme {
        settingsVM.selectedTheme
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Theme") {
                    Text("Choose one theme for onboarding, settings, and overlay.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Picker(
                        "Theme",
                        selection: Binding(
                            get: { selectedTheme },
                            set: { settingsVM.setTheme($0) }
                        )
                    ) {
                        ForEach(defaultThemes, id: \.self) { theme in
                            Text(ThemeText.title(for: theme)).tag(theme)
                        }

                        Divider()

                        ForEach(customThemes, id: \.self) { theme in
                            Text(ThemeText.title(for: theme)).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(ThemeText.description(for: selectedTheme))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SettingsSection(title: "Preview") {
                    VStack(spacing: 10) {
                        ThemePreviewCard(theme: selectedTheme)
                            .frame(maxWidth: 640)
                            .frame(maxWidth: .infinity)

                        Text("This theme is currently active.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct ThemePreviewCard: View {
    let theme: Preferences.Theme

    private var scheme: ColorScheme {
        ThemeModeResolver.effectiveColorScheme(for: theme.mode)
    }

    private var primaryText: Color {
        switch theme {
        case .system:
            return scheme == .dark
                ? Color.white.opacity(0.93)
                : Color(red: 0.15, green: 0.17, blue: 0.22)
        case .light:
            return Color(red: 0.15, green: 0.17, blue: 0.22)
        case .dark, .graphite:
            return Color.white.opacity(0.93)
        case .warmPaper:
            return Color(red: 0.25, green: 0.19, blue: 0.12)
        case .nordMist:
            return Color(red: 0.89, green: 0.94, blue: 0.98)
        case .highContrast:
            return scheme == .dark ? .white : .black
        }
    }

    private var secondaryText: Color {
        switch theme {
        case .system:
            return scheme == .dark
                ? Color.white.opacity(0.72)
                : Color(red: 0.31, green: 0.34, blue: 0.41)
        case .light:
            return Color(red: 0.31, green: 0.34, blue: 0.41)
        case .dark, .graphite:
            return Color.white.opacity(0.72)
        case .warmPaper:
            return Color(red: 0.39, green: 0.30, blue: 0.21)
        case .nordMist:
            return Color(red: 0.71, green: 0.80, blue: 0.89)
        case .highContrast:
            return scheme == .dark ? Color.white.opacity(0.88) : Color.black.opacity(0.82)
        }
    }

    var body: some View {
        let palette = ThemePalette.resolved(for: theme.preset, scheme: scheme)
        ZStack {
            palette.overlayBackdrop
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.15),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.7))
                        .frame(width: 10, height: 10)
                    Text("Preview Overlay")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(primaryText)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(palette.overlaySearchBackground)
                        .frame(width: 100, height: 18)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider()

                HStack(alignment: .top, spacing: 10) {
                    ThemePreviewColumn(
                        title: "App",
                        rows: ["Hide", "Preferences", "Quit"],
                        palette: palette,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                    ThemePreviewColumn(
                        title: "Window",
                        rows: ["Minimize", "Zoom", "Bring All to Front"],
                        palette: palette,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                    ThemePreviewColumn(
                        title: "Help",
                        rows: ["Search", "Support", "Shortcuts"],
                        palette: palette,
                        primaryText: primaryText,
                        secondaryText: secondaryText
                    )
                }
                .padding(10)
            }
            .background(palette.overlayPanelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(palette.overlayPanelBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(20)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.overlayPanelBorder.opacity(0.65), lineWidth: 1)
        )
        .preferredColorScheme(scheme)
    }
}

private struct ThemePreviewColumn: View {
    let title: String
    let rows: [String]
    let palette: ThemePalette
    let primaryText: Color
    let secondaryText: Color
    private let keySamples = ["⌘1", "⌘2", "⌘3", "⌘4", "⌘5", "⌘6"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryText)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 4) {
                    Text(row)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(primaryText)
                    Spacer(minLength: 4)
                    Text(keySamples[index % keySamples.count])
                        .font(.caption.monospaced())
                        .foregroundStyle(secondaryText)
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 5)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(palette.overlayRowBackground)
                )
            }
        }
    }
}

// MARK: - Help Tab

struct HelpSettingsTab: View {
    @ObservedObject var feedbackVM: FeedbackViewModel
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    private var palette: ThemePalette {
        ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
    }

    private var inputBackground: Color {
        palette.overlaySearchBackground
    }

    private var inputBorder: Color {
        palette.overlayPanelBorder.opacity(0.9)
    }

    private var inputCornerRadius: CGFloat {
        8
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection(title: "Send Feedback") {
                    Text("Share suggestions or report issues. Title is limited to \(feedbackVM.maxTitleLength) characters and message to \(feedbackVM.maxMessageLength) characters.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email (optional)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField(
                            "you@example.com",
                            text: Binding(
                                get: { feedbackVM.email },
                                set: { feedbackVM.setEmail($0) }
                            )
                        )
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
                                    .fill(inputBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
                                    .stroke(inputBorder, lineWidth: 1)
                            )
                            .textContentType(.emailAddress)

                        if feedbackVM.hasInvalidEmail {
                            Text("Please enter a valid email format.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Title")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(feedbackVM.titleCountText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        FeedbackSingleLineTextField(
                            text: Binding(
                                get: { feedbackVM.title },
                                set: { feedbackVM.setTitle($0) }
                            ),
                            placeholder: "Short summary",
                            maxLength: feedbackVM.maxTitleLength
                        )
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
                                    .fill(inputBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: inputCornerRadius, style: .continuous)
                                    .stroke(inputBorder, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Message")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(feedbackVM.messageCountText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        FeedbackMessageInput(
                            text: Binding(
                                get: { feedbackVM.message },
                                set: { feedbackVM.setMessage($0) }
                            ),
                            placeholder: "Tell us what happened and what you expected.",
                            maxLength: feedbackVM.maxMessageLength,
                            background: inputBackground,
                            border: inputBorder,
                            cornerRadius: inputCornerRadius
                        )
                        .frame(minHeight: 178)
                    }

                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await feedbackVM.submit()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if feedbackVM.isSubmitting {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(feedbackVM.isSubmitting ? "Submitting..." : "Submit Feedback")
                            }
                        }
                        .disabled(!feedbackVM.canSubmit)
                        .applyDisabledButtonAppearance()
                    }

                    if let successMessage = feedbackVM.successMessage {
                        Text(successMessage)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    if let errorMessage = feedbackVM.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
    }
}

private struct FeedbackSingleLineTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, maxLength: maxLength)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: "")
        field.isBordered = false
        field.bezelStyle = .squareBezel
        field.focusRingType = .none
        field.drawsBackground = false
        field.isBezeled = false
        field.isEditable = true
        field.isSelectable = true
        field.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        field.textColor = NSColor.labelColor
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.stringValue = text
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.maxLength = maxLength

        if nsView.placeholderString != placeholder {
            nsView.placeholderString = placeholder
        }

        if nsView.stringValue != text {
            context.coordinator.isProgrammaticUpdate = true
            nsView.stringValue = text
            context.coordinator.isProgrammaticUpdate = false
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String
        var maxLength: Int
        var isProgrammaticUpdate = false

        init(text: Binding<String>, maxLength: Int) {
            _text = text
            self.maxLength = maxLength
        }

        func controlTextDidChange(_ obj: Notification) {
            guard !isProgrammaticUpdate,
                  let field = obj.object as? NSTextField else { return }

            if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() {
                return
            }

            applyLimitAndSync(field)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            applyLimitAndSync(field)
        }

        private func applyLimitAndSync(_ field: NSTextField) {
            var value = field.stringValue
            if value.count > maxLength {
                value = String(value.prefix(maxLength))
                field.stringValue = value
            }
            text = value
        }
    }
}

private struct FeedbackMessageInput: View {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    let background: Color
    let border: Color
    let cornerRadius: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            FeedbackMessageTextEditor(
                text: $text,
                maxLength: maxLength
            )

            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 11)
                    .padding(.top, 9)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }
}

private struct FeedbackMessageTextEditor: NSViewRepresentable {
    @Binding var text: String
    let maxLength: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, maxLength: maxLength)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = NSColor.labelColor
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.delegate = context.coordinator
        textView.string = text

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context _: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        private let maxLength: Int

        init(text: Binding<String>, maxLength: Int) {
            _text = text
            self.maxLength = maxLength
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            guard let replacementString else { return true }

            let currentText = textView.string
            let currentNSString = currentText as NSString
            let nextText = currentNSString.replacingCharacters(
                in: affectedCharRange,
                with: replacementString
            )

            if nextText.count <= maxLength {
                return true
            }

            let replacedText = currentNSString.substring(with: affectedCharRange)
            let availableCount = maxLength - (currentText.count - replacedText.count)
            guard availableCount > 0 else { return false }

            let allowedText = String(replacementString.prefix(availableCount))
            guard !allowedText.isEmpty else { return false }

            let cappedText = currentNSString.replacingCharacters(in: affectedCharRange, with: allowedText)
            textView.string = cappedText
            textView.setSelectedRange(
                NSRange(
                    location: affectedCharRange.location + (allowedText as NSString).length,
                    length: 0
                )
            )
            text = cappedText
            return false
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            if textView.string.count > maxLength {
                let capped = String(textView.string.prefix(maxLength))
                textView.string = capped
                textView.setSelectedRange(NSRange(location: (capped as NSString).length, length: 0))
                text = capped
                return
            }

            text = textView.string
        }
    }
}

// MARK: - Onboarding Trigger Settings (simplified for RootView)

struct OnboardingTriggerSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsSection(title: "Trigger Settings") {
            Picker(
                "Default Trigger",
                selection: Binding(
                    get: { viewModel.selectedTriggerType == .commandDoubleTap ? .commandDoubleTap : .holdCommand },
                    set: { viewModel.setTriggerType($0) }
                )
            ) {
                Text("Hold ⌘ Command").tag(Preferences.Trigger.holdCommand)
                Text("Double-tap ⌘ Command").tag(Preferences.Trigger.commandDoubleTap)
            }
            .pickerStyle(.menu)

            if viewModel.selectedTriggerType == .holdCommand {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Hold Duration")
                        Spacer()
                        Text("\(viewModel.holdDuration, specifier: "%.1f")s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { viewModel.holdDuration },
                            set: { viewModel.setHoldDuration($0) }
                        ),
                        in: 0.3...3.0,
                        step: 0.1
                    )
                }
            }
        }
    }
}

// MARK: - Reusable Section Container

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @Environment(\.appEffectiveColorScheme) private var appEffectiveColorScheme
    @Environment(\.appThemePreset) private var appThemePreset

    var body: some View {
        let palette = ThemePalette.resolved(for: appThemePreset, scheme: appEffectiveColorScheme)
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.settingsSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
