import SwiftUI
import WidgetKit

/// F01 온보딩: 소개 → 테마 → 목표 → 건강 권한 → 위젯 안내. 단계는 저장되어 재실행 시 이어서 시작한다.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch model.onboarding.currentStep {
            case .intro: IntroStep()
            case .theme: ThemeStep()
            case .goal: GoalStep()
            case .health: HealthStep()
            case .widgetGuide: WidgetGuideStep()
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        .animation(.snappy, value: model.onboarding.currentStep)
    }
}

/// 온보딩 공통 레이아웃: 제목·설명 → 내용 → 하단 버튼
private struct OnboardingPage<Content: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let primaryTitle: LocalizedStringKey
    let primaryAction: () -> Void
    let secondaryTitle: LocalizedStringKey?
    let secondaryAction: () -> Void
    let content: Content

    init(
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        primaryTitle: LocalizedStringKey,
        primaryAction: @escaping () -> Void,
        secondaryTitle: LocalizedStringKey? = nil,
        secondaryAction: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.largeTitle.weight(.black))
                if let message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            content
                .frame(maxHeight: .infinity)

            VStack(spacing: 12) {
                Button(action: primaryAction) {
                    Text(primaryTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)

                if let secondaryTitle {
                    Button(secondaryTitle, action: secondaryAction)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }
}

// MARK: - 1. Intro

private struct IntroStep: View {
    @Environment(AppModel.self) private var model
    @State private var stage = 0

    private var theme: Theme { ThemeRegistry.resolvedTheme(id: ThemeRegistry.defaultThemeID) }

    var body: some View {
        OnboardingPage(
            title: "Walk it. Get it.",
            message: "Pick the look you want. Every step you take changes your home screen. Literally.",
            primaryTitle: "Let's go",
            primaryAction: { model.advanceOnboarding(to: .theme) }
        ) {
            VStack(spacing: 20) {
                Text(AppConstants.appName)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .tracking(-1)
                StageCard(theme: theme, stage: stage, size: .large, appearance: model.appearance)
                    .aspectRatio(1092.0 / 1146.0, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 32))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: stage)
            }
        }
        .task {
            // 0단계 → 마지막 단계 변화를 반복 재생
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(stage == theme.lastStage ? 1_500 : 350))
                stage = stage >= theme.lastStage ? 0 : stage + 1
            }
        }
    }
}

// MARK: - 2. Theme

private struct ThemeStep: View {
    @Environment(AppModel.self) private var model
    @State private var selectedID: String?

    var body: some View {
        OnboardingPage(
            title: "Okay, what's your vibe?",
            message: "Whatever you pick shows up on your widget. You can switch anytime, no pressure.",
            primaryTitle: "Next",
            primaryAction: next
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ThemeRegistry.availableThemes()) { theme in
                        ThemeCard(theme: theme, isSelected: (selectedID ?? model.settings.themeID) == theme.id)
                            .onTapGesture { selectedID = theme.id }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func next() {
        var settings = model.settings
        settings.themeID = selectedID ?? settings.themeID
        Task { await model.updateSettings(settings) }
        model.advanceOnboarding(to: .goal)
    }
}

/// 좌우로 밀면 0단계 → 마지막 단계 미리보기 (F01-R2)
private struct ThemeCard: View {
    @Environment(AppModel.self) private var model
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TabView {
                ForEach(0...theme.lastStage, id: \.self) { stage in
                    StageCard(theme: theme, stage: stage, size: .medium, appearance: model.appearance)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 150)
            .clipShape(.rect(cornerRadius: 18))

            HStack {
                Text(theme.displayName)
                    .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            Text(theme.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background.secondary, in: .rect(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(.rect)
    }
}

// MARK: - 3. Goal

private struct GoalStep: View {
    @Environment(AppModel.self) private var model
    @State private var period: GoalPeriod = .daily
    @State private var target = 10_000
    @State private var showsAdjustNotice = false
    @State private var didLoad = false

    private var descriptor: MetricDescriptor { .for(.steps) }

    var body: some View {
        OnboardingPage(
            title: "Now pick your goal",
            primaryTitle: "Next",
            primaryAction: next
        ) {
            VStack(spacing: 24) {
                Picker("Period", selection: Binding(
                    get: { period },
                    set: { newPeriod in
                        period = newPeriod
                        target = descriptor.defaultTarget(for: newPeriod)
                        showsAdjustNotice = false
                    }
                )) {
                    Text("Daily").tag(GoalPeriod.daily)
                    Text("Weekly").tag(GoalPeriod.weekly)
                }
                .pickerStyle(.segmented)

                GoalTargetField(period: period, target: $target, showsAdjustNotice: $showsAdjustNotice)

                Group {
                    switch period {
                    case .daily:
                        Text("Hit your goal and the \(model.theme.displayName) is yours. Every. Single. Day.")
                    case .weekly:
                        Text("Resets every Sunday. New week, new you.")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            period = model.settings.period
            target = model.settings.target
        }
    }

    private func next() {
        let result = descriptor.clampedTarget(target, for: period)
        if result.wasAdjusted {
            // 보정 결과를 먼저 보여주고, 한 번 더 누르면 넘어간다
            target = result.value
            showsAdjustNotice = true
            return
        }
        var settings = model.settings
        settings.period = period
        settings.target = result.value
        Task { await model.updateSettings(settings) }
        model.advanceOnboarding(to: .health)
    }
}

// MARK: - 4. Health

private struct HealthStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        OnboardingPage(
            title: "Can I peek at your steps?",
            message: "I only read your step count from Health. Read-only, and it never leaves your phone. Pinky promise 🤙",
            primaryTitle: "Sure, go ahead",
            primaryAction: {
                Task {
                    await model.requestHealthAccess()
                    model.advanceOnboarding(to: .widgetGuide)
                }
            },
            secondaryTitle: "Maybe later",
            secondaryAction: { model.advanceOnboarding(to: .widgetGuide) }
        ) {
            Image(systemName: "figure.walk")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.tint)
        }
    }
}

// MARK: - 5. Widget guide

private struct WidgetGuideStep: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        OnboardingPage(
            title: "Last step, and it's the big one!",
            message: "Put me on your home screen.",
            primaryTitle: "Done",
            primaryAction: { model.completeOnboarding() }
        ) {
            VStack(alignment: .leading, spacing: 14) {
                // 실제 위젯 모습 미리보기 + 배경 색 선택 (F07-R5)
                WidgetPreview(
                    snapshot: .sample(themeID: model.theme.id, stage: model.theme.lastStage / 2),
                    family: .systemLarge,
                    appearance: model.appearance
                )
                // 실제 Large 위젯 크기로 그린 뒤 축소 (글자 비율 유지)
                .frame(width: 364, height: 382)
                .clipShape(.rect(cornerRadius: 44))
                .scaleEffect(0.52)
                .frame(width: 364 * 0.52, height: 382 * 0.52)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                .frame(maxWidth: .infinity)
                Text("Pick a color that vibes with your home screen 🎨")
                    .font(.subheadline.weight(.semibold))
                BackgroundPicker(selection: Binding(
                    get: { model.appearance },
                    set: { model.updateAppearance($0) }
                ))
                VStack(alignment: .leading, spacing: 8) {
                    GuideRow(number: 1, text: "Long-press an empty spot")
                    GuideRow(number: 2, text: "Tap + at the top left")
                    GuideRow(number: 3, text: "Search \"\(AppConstants.appName)\"")
                    GuideRow(number: 4, text: "Pick the big one")
                }
                Text("Bigger widget = bigger glow-up. Trust me.")
                    .font(.footnote.weight(.semibold))
            }
        }
    }
}

private struct GuideRow: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline.weight(.black))
                .frame(width: 30, height: 30)
                .background(.tint.opacity(0.18), in: .circle)
            Text(text)
        }
    }
}
