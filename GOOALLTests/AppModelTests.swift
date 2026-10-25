import Foundation
import Testing
@testable import GOOALL

@MainActor
private final class FakeHealthSource: HealthDataSource {
    var steps = 0
    /// 오늘 0시부터 읽을 때 돌려줄 값 (주간 todayValue 확인용). nil이면 steps
    var todaySteps: Int?
    var shouldThrow = false
    /// 값을 정한 뒤 돌려주기 전에 실행 (읽는 도중 설정이 바뀌는 경합 재현용)
    var onTotal: (() async -> Void)?
    private(set) var totalCalls = 0

    var isAvailable: Bool { true }
    func requestAuthorization() async {}
    func total(from start: Date, to end: Date) async throws -> Int {
        totalCalls += 1
        if shouldThrow { throw CocoaError(.fileReadNoPermission) }
        let isToday = start == Calendar.current.startOfDay(for: end)
        let result = isToday ? (todaySteps ?? steps) : steps
        await onTotal?()
        return result
    }
    func startObserving(onUpdate: @escaping @Sendable (_ done: @escaping @Sendable () -> Void) -> Void) async {}
}

@MainActor
private final class ReloadCounter {
    var count = 0
}

/// F01-R6 설정 변경 흐름, F02 갱신 흐름, F06 표시 스냅샷
@MainActor
struct AppModelTests {

    private func makeStore() -> SharedStore {
        SharedStore(defaults: UserDefaults(suiteName: "AppModelTests-\(UUID().uuidString)")!)
    }

    @Test func refreshStoresSnapshot() async throws {
        let store = makeStore()
        let health = FakeHealthSource()
        health.steps = 6_240
        let model = AppModel(store: store, health: health)

        await model.refresh()

        #expect(model.snapshot?.value == 6_240)
        #expect(model.snapshot?.stage == 6)
        // JSON 저장 시 updatedAt의 소수점 아래 미세한 자리는 달라질 수 있어 따로 비교한다
        let saved = try #require(store.progressSnapshot)
        let current = try #require(model.snapshot)
        #expect(saved.value == current.value)
        #expect(saved.stage == current.stage)
        #expect(saved.periodStart == current.periodStart)
        #expect(abs(saved.updatedAt.timeIntervalSince(current.updatedAt)) < 0.001)
    }

    @Test func failedRefreshKeepsLastSnapshot() async {
        let store = makeStore()
        let health = FakeHealthSource()
        health.steps = 3_000
        let model = AppModel(store: store, health: health)
        await model.refresh()

        health.shouldThrow = true
        health.steps = 9_000
        await model.refresh()

        #expect(model.snapshot?.value == 3_000)
    }

    @Test func changingTargetKeepsValueAndRecalculatesStage() async {
        let store = makeStore()
        let health = FakeHealthSource()
        health.steps = 5_000
        let model = AppModel(store: store, health: health)
        await model.refresh()
        #expect(model.snapshot?.stage == 5)

        // 같은 기간 안의 설정 변경은 HealthKit을 다시 읽지 않고 값을 유지한다
        health.steps = 9_999
        let callsBefore = health.totalCalls
        var settings = model.settings
        settings.target = 5_000
        settings.themeID = "eyeglow"
        await model.updateSettings(settings)

        #expect(health.totalCalls == callsBefore)
        #expect(model.snapshot?.value == 5_000)
        #expect(model.snapshot?.stage == 10)
        #expect(model.snapshot?.themeID == "eyeglow")
        #expect(store.goalSettings == settings)
    }

    @Test func changingPeriodRereadsHealthData() async {
        let store = makeStore()
        let health = FakeHealthSource()
        health.steps = 5_000
        let model = AppModel(store: store, health: health)
        await model.refresh()

        health.steps = 30_000
        var settings = model.settings
        settings.period = .weekly
        settings.target = 70_000
        await model.updateSettings(settings)

        #expect(model.snapshot?.period == .weekly)
        #expect(model.snapshot?.value == 30_000)
    }

    /// F07-R5: 배경 색 변경은 저장되고, 같은 값이면 아무것도 하지 않는다
    @Test func updatingAppearancePersists() {
        let store = makeStore()
        let model = AppModel(store: store, health: FakeHealthSource())
        #expect(model.appearance == .default)

        model.updateAppearance(WidgetAppearance(backgroundID: "lavender"))
        #expect(model.appearance.backgroundID == "lavender")
        #expect(store.widgetAppearance.backgroundID == "lavender")
        #expect(AppModel(store: store, health: FakeHealthSource()).appearance.backgroundID == "lavender")
    }

    @Test func staleSnapshotIsShownAsZeroAndNotCarriedIntoNewSettings() async {
        let store = makeStore()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        store.progressSnapshot = ProgressEngine.makeSnapshot(
            value: 9_000, todayValue: 9_000, settings: .default, stageCount: 11,
            now: yesterday, calendar: .current
        )
        let health = FakeHealthSource()
        health.shouldThrow = true
        let model = AppModel(store: store, health: health)

        #expect(model.displaySnapshot?.value == 0)
        #expect(model.displaySnapshot?.stage == 0)

        var settings = model.settings
        settings.themeID = "eyeglow"
        await model.updateSettings(settings)

        #expect(model.snapshot?.value == 0)
        #expect(model.snapshot?.periodStart == Calendar.current.startOfDay(for: .now))
    }

    /// F02-R5: 단계가 같으면 위젯을 갱신하지 않고, 바뀌면 한 번 갱신한다
    @Test func widgetReloadsOnlyWhenStageChanges() async {
        let reloads = ReloadCounter()
        let health = FakeHealthSource()
        health.steps = 5_000
        let model = AppModel(store: makeStore(), health: health, reloadWidgets: { reloads.count += 1 })
        await model.refresh()
        #expect(reloads.count == 1)   // 스냅샷 없음 → 5단계

        health.steps = 5_400          // 여전히 5단계
        await model.refresh()
        #expect(reloads.count == 1)

        health.steps = 6_000          // 6단계
        await model.refresh()
        #expect(reloads.count == 2)
    }

    /// F02: 주간 목표의 todayValue는 오늘 0시부터의 합계 (일요일이 아닌 날로 고정)
    @Test func weeklyTodayValueIsTodaysSteps() async throws {
        let store = makeStore()
        var settings = GoalSettings.default
        settings.period = .weekly
        settings.target = 70_000
        store.goalSettings = settings
        let health = FakeHealthSource()
        health.steps = 30_000
        health.todaySteps = 4_200
        let model = AppModel(store: store, health: health)
        let wednesday = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 21, hour: 12)))

        await model.refresh(now: wednesday)

        #expect(model.snapshot?.value == 30_000)
        #expect(model.snapshot?.todayValue == 4_200)
    }

    /// 읽는 도중 설정이 바뀌면 옛 설정으로 읽은 결과는 버린다 (refresh 경합)
    @Test func refreshDiscardsResultReadWithOldSettings() async {
        let health = FakeHealthSource()
        health.steps = 3_000
        let model = AppModel(store: makeStore(), health: health)
        var newSettings = model.settings
        newSettings.target = 5_000
        health.onTotal = {
            health.onTotal = nil
            health.steps = 8_000
            await model.updateSettings(newSettings)   // 새 설정으로 다시 읽음 → 8,000
        }

        await model.refresh()   // 3,000을 읽었지만 그사이 설정이 바뀜 → 버림

        #expect(model.snapshot?.value == 8_000)
        #expect(model.snapshot?.target == 5_000)
    }

    /// F01: 온보딩 중 앱을 다시 켜면 중단된 단계에서 재개
    @Test func onboardingResumesAtSavedStep() {
        let store = makeStore()
        AppModel(store: store, health: FakeHealthSource()).advanceOnboarding(to: .health)

        let relaunched = AppModel(store: store, health: FakeHealthSource())
        #expect(relaunched.onboarding.currentStep == .health)
        #expect(!relaunched.onboarding.isCompleted)
    }

    /// F06: 오늘 화면은 위젯 타임라인과 같은 함수로 현재 엔트리를 고른다 (같은 시점 = 같은 단계)
    @Test func displaySnapshotMatchesWidgetCurrentEntry() async throws {
        let store = makeStore()
        let health = FakeHealthSource()
        health.steps = 7_300
        let model = AppModel(store: store, health: health)
        await model.refresh()

        let saved = try #require(store.progressSnapshot)
        let widgetCurrent = ProgressEngine.timelineSnapshots(from: saved, now: .now, calendar: .current)[0]
        #expect(model.displaySnapshot?.stage == widgetCurrent.stage)
        #expect(model.displaySnapshot?.value == widgetCurrent.value)
    }
}
