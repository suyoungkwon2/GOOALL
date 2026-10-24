import Foundation
import Observation
import WidgetKit

/// 앱 상태와 갱신 흐름. 계산은 ProgressEngine, 저장은 SharedStore에 맡긴다.
@Observable
final class AppModel {
    enum HealthHint {
        case none
        case notRequested   // "Maybe later"를 눌러 아직 권한을 요청하지 않음
        case maybeDenied    // 요청했지만 오늘 값이 0 (거부인지 실제 0인지 알 수 없음, F02)
    }

    private let store: SharedStore
    private let health: HealthDataSource

    private(set) var settings: GoalSettings
    private(set) var snapshot: ProgressSnapshot?
    private(set) var onboarding: OnboardingState
    private(set) var healthAuthRequested: Bool
    private(set) var appearance: WidgetAppearance
    /// 날짜가 바뀌면 갱신되어 displaySnapshot을 다시 계산하게 한다
    private var dayTick = Date()
    #if DEBUG
    private(set) var debugMockSteps: Int?
    #endif

    init(store: SharedStore = .shared, health: HealthDataSource = HealthKitStepSource()) {
        self.store = store
        self.health = health
        settings = store.goalSettings ?? .default
        snapshot = store.progressSnapshot
        onboarding = store.onboardingState ?? .initial
        healthAuthRequested = store.healthAuthRequested
        appearance = store.widgetAppearance
        #if DEBUG
        debugMockSteps = store.debugMockSteps
        applyDebugLaunchArguments()
        #endif
        // 앱이 켜진 채 자정(또는 시간대 변경)을 지나면 즉시 갱신한다
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.dayTick = Date()
                Task { await self?.refresh() }
            }
        }
    }

    var theme: Theme { ThemeRegistry.resolvedTheme(id: settings.themeID) }

    /// 화면에 보여줄 스냅샷. 저장된 스냅샷의 기간이 지났으면 위젯과 같은 규칙으로 현재 기간 0 상태로 본다.
    var displaySnapshot: ProgressSnapshot? {
        _ = dayTick
        guard let snapshot else { return nil }
        return ProgressEngine.timelineSnapshots(from: snapshot, now: .now, calendar: .current)[0]
    }

    var healthHint: HealthHint {
        #if DEBUG
        if debugMockSteps != nil { return .none }
        #endif
        if !healthAuthRequested { return .notRequested }
        return (displaySnapshot?.todayValue ?? 0) == 0 ? .maybeDenied : .none
    }

    // MARK: - Onboarding (F01)

    func advanceOnboarding(to step: OnboardingStep) {
        onboarding.currentStep = step
        store.onboardingState = onboarding
    }

    func completeOnboarding() {
        onboarding.isCompleted = true
        store.onboardingState = onboarding
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Settings (F01-R6)

    /// 진행 값은 유지하고 단계만 재계산한다. 기간이 바뀌면 값 자체가 달라지므로 다시 읽는다.
    func updateSettings(_ newSettings: GoalSettings) async {
        guard newSettings != settings else { return }
        let periodChanged = newSettings.period != settings.period
        settings = newSettings
        store.goalSettings = newSettings
        // 지난 기간 값을 이번 기간으로 옮기지 않도록 displaySnapshot(기간 지나면 0)을 쓴다
        if let current = displaySnapshot, !periodChanged {
            apply(value: current.value, todayValue: current.todayValue, now: .now, forceWidgetReload: true)
        } else {
            await refresh()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Widget appearance (F07)

    func updateAppearance(_ newAppearance: WidgetAppearance) {
        guard newAppearance != appearance else { return }
        appearance = newAppearance
        store.widgetAppearance = newAppearance
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Health (F02)

    func requestHealthAccess() async {
        await health.requestAuthorization()
        healthAuthRequested = true
        store.healthAuthRequested = true
        await startBackgroundUpdates()
        await refresh()
    }

    func startBackgroundUpdates() async {
        guard healthAuthRequested else { return }
        await health.startObserving { [weak self] done in
            Task { @MainActor in
                await self?.refresh()
                done()
            }
        }
    }

    func refresh(now: Date = .now) async {
        #if DEBUG
        if let debugMockSteps {
            apply(value: debugMockSteps, todayValue: debugMockSteps, now: now)
            return
        }
        #endif
        let requested = settings
        let calendar = Calendar.current
        let period = ProgressEngine.periodInterval(for: requested.period, at: now, calendar: calendar)
        let value: Int
        let todayValue: Int
        do {
            value = try await health.total(from: period.start, to: now)
            todayValue = requested.period == .daily
                ? value
                : try await health.total(from: calendar.startOfDay(for: now), to: now)
        } catch {
            return  // 잠금 등으로 읽지 못하면 마지막 스냅샷을 유지한다
        }
        // 읽는 동안 설정이 바뀌었으면 이 결과는 버린다 (바뀐 설정의 refresh가 따로 돈다)
        guard settings == requested else { return }
        apply(value: value, todayValue: todayValue, now: now)
    }

    /// 스냅샷 저장 후 단계가 바뀐 경우에만 위젯을 갱신한다 (F02-R5).
    private func apply(value: Int, todayValue: Int, now: Date, forceWidgetReload: Bool = false) {
        let newSnapshot = ProgressEngine.makeSnapshot(
            value: value,
            todayValue: todayValue,
            settings: settings,
            stageCount: theme.stageCount,
            now: now,
            calendar: .current
        )
        let previousStage = snapshot?.stage
        snapshot = newSnapshot
        store.progressSnapshot = newSnapshot
        if forceWidgetReload || previousStage != newSnapshot.stage {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Debug (F02-R8)

    #if DEBUG
    func setDebugMockSteps(_ steps: Int?) async {
        debugMockSteps = steps
        store.debugMockSteps = steps
        await refresh()
    }

    /// 시뮬레이터 스크린샷용: -debugOnboardingStep <step>, -debugSkipOnboarding, -debugMockSteps <n>, -debugPeriod weekly, -debugTheme <id>, -debugBackground <id>
    private func applyDebugLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }
        if let raw = value(after: "-debugOnboardingStep"), let step = OnboardingStep(rawValue: raw) {
            onboarding = OnboardingState(currentStep: step, isCompleted: false)
        }
        if arguments.contains("-debugSkipOnboarding") {
            onboarding.isCompleted = true
        }
        if let raw = value(after: "-debugPeriod"), let period = GoalPeriod(rawValue: raw) {
            settings.period = period
            settings.target = MetricDescriptor.for(settings.metric).defaultTarget(for: period)
        }
        if let themeID = value(after: "-debugTheme"), ThemeRegistry.theme(id: themeID) != nil {
            settings.themeID = themeID
        }
        if let backgroundID = value(after: "-debugBackground") {
            appearance = WidgetAppearance(backgroundID: backgroundID)
        }
        if let raw = value(after: "-debugMockSteps"), let steps = Int(raw) {
            debugMockSteps = steps
        }
    }
    #endif
}
