import SwiftUI

/// F01-R6 설정: 테마·목표 변경 즉시 위젯 반영
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft = GoalSettings.default
    @State private var showsAdjustNotice = false
    @State private var didLoad = false

    private var descriptor: MetricDescriptor { .for(draft.metric) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    Picker("Theme", selection: $draft.themeID) {
                        ForEach(ThemeRegistry.availableThemes()) { theme in
                            Text(theme.displayName).tag(theme.id)
                        }
                    }
                }

                Section {
                    // 사용자가 기간을 바꿀 때만 목표를 기본값으로 (화면 로드 시 저장값이 덮어써지지 않도록)
                    Picker("Period", selection: Binding(
                        get: { draft.period },
                        set: { newPeriod in
                            draft.period = newPeriod
                            draft.target = descriptor.defaultTarget(for: newPeriod)
                        }
                    )) {
                        Text("Daily").tag(GoalPeriod.daily)
                        Text("Weekly").tag(GoalPeriod.weekly)
                    }
                    .pickerStyle(.segmented)
                    GoalTargetField(period: draft.period, target: $draft.target, showsAdjustNotice: $showsAdjustNotice)
                        .padding(.vertical, 8)
                } header: {
                    Text("Goal")
                } footer: {
                    Text("Your steps update about once an hour (iOS decides the exact timing). Open the app to refresh right away.")
                }

                Section("Widget") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Background")
                        BackgroundPicker(selection: Binding(
                            get: { model.appearance },
                            set: { model.updateAppearance($0) }
                        ))
                    }
                    .padding(.vertical, 4)
                }

                Section("About") {
                    Link("Privacy Policy", destination: AppConstants.privacyPolicyURL)
                    LabeledContent("Version", value: Bundle.main.appVersion)
                }

                #if DEBUG
                DebugSection()
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            draft = model.settings
        }
        .onChange(of: draft) { _, newDraft in
            // 입력 중인 범위 밖 값은 저장하지 않는다 (포커스가 빠질 때 보정됨)
            guard didLoad, descriptor.allowedRange(for: newDraft.period).contains(newDraft.target) else { return }
            Task { await model.updateSettings(newDraft) }
        }
    }
}

private extension Bundle {
    /// "1.0 (1)" 형식
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

#if DEBUG
/// F02-R8 가짜 걸음 수 (DEBUG 빌드 전용)
private struct DebugSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Section("Debug") {
            Toggle("Use fake steps", isOn: Binding(
                get: { model.debugMockSteps != nil },
                set: { on in Task { await model.setDebugMockSteps(on ? model.settings.target / 2 : nil) } }
            ))
            if let steps = model.debugMockSteps {
                Text("\(steps.formatted()) steps")
                    .monospacedDigit()
                Slider(
                    value: Binding(
                        get: { Double(steps) },
                        set: { newValue in Task { await model.setDebugMockSteps(Int(newValue)) } }
                    ),
                    in: 0...Double(model.settings.target) * 1.2,
                    step: 100
                )
            }
        }
    }
}
#endif
