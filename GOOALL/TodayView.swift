import SwiftUI
import UIKit

/// F06 오늘 화면
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var showsSettings = false
    @State private var previewStage: Double = 0
    @State private var isPreviewing = false

    private var theme: Theme { model.theme }
    private var settings: GoalSettings { model.settings }
    private var value: Int { model.displaySnapshot?.value ?? 0 }
    private var todayValue: Int { model.displaySnapshot?.todayValue ?? 0 }
    private var currentStage: Int { model.displaySnapshot?.stage ?? 0 }
    private var isComplete: Bool { model.displaySnapshot?.isComplete ?? false }
    private var shownStage: Int { isPreviewing ? Int(previewStage) : currentStage }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StageCard(theme: theme, stage: shownStage, size: .large, appearance: model.appearance)
                        .aspectRatio(1092.0 / 1146.0, contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 32))
                        .animation(.easeInOut(duration: 0.25), value: shownStage)

                    stats
                    message
                    healthHint
                    sneakPeek
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .refreshable { await model.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(AppConstants.appName)
                        .font(.title3.weight(.black))
                        .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showsSettings = true }
                }
            }
            .sheet(isPresented: $showsSettings) { SettingsView() }
            .task { await model.refresh() }
        }
    }

    // MARK: - Sections

    /// F06-R2, R8
    private var stats: some View {
        VStack(spacing: 6) {
            Text(settings.period == .daily ? "Today" : "This week")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Text("\(value.formatted()) / \(settings.target.formatted())\(value > settings.target ? " 🎉" : "")")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .monospacedDigit()
            Group {
                if isComplete {
                    Text("Goal crushed 🎉")
                } else {
                    Text("\((settings.target - value).formatted()) steps to go")
                }
            }
            .font(.subheadline.weight(.semibold))

            if settings.period == .weekly {
                Text("Today \(todayValue.formatted()) / avg goal \(ProgressEngine.dailyAverageTarget(weeklyTarget: settings.target).formatted())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// F06-R7, R9
    @ViewBuilder
    private var message: some View {
        if isComplete {
            Text(theme.doneMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
        } else if currentStage == 0 {
            Text(theme.startMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
    }

    /// F06-R5
    @ViewBuilder
    private var healthHint: some View {
        switch model.healthHint {
        case .none:
            EmptyView()
        case .notRequested:
            HintCard(
                text: "Wanna see your real steps? Let me peek at Health.",
                buttonTitle: "Turn it on"
            ) {
                Task { await model.requestHealthAccess() }
            }
        case .maybeDenied:
            HintCard(
                text: "Hmm, I'm seeing 0 steps. If Health access is off, you can turn it on in Settings.",
                buttonTitle: "Open Settings"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        }
    }

    /// F06-R4. 미리보기는 표시만 바꾸고 스냅샷은 건드리지 않는다.
    private var sneakPeek: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sneak peek")
                    .font(.headline)
                Spacer()
                if isPreviewing {
                    Button("Back to now") {
                        isPreviewing = false
                        previewStage = Double(currentStage)
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            Slider(value: $previewStage, in: 0...Double(max(theme.lastStage, 1)), step: 1) { editing in
                if editing { isPreviewing = true }
            }
        }
        .padding(16)
        .background(.background.secondary, in: .rect(cornerRadius: 22))
        .onAppear { previewStage = Double(currentStage) }
        .onChange(of: currentStage) { _, stage in
            if !isPreviewing { previewStage = Double(stage) }
        }
    }
}

private struct HintCard: View {
    let text: LocalizedStringKey
    let buttonTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button(buttonTitle, action: action)
                .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 22))
    }
}
