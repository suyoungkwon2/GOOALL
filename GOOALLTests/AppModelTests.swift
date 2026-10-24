import Foundation
import Testing
@testable import GOOALL

@MainActor
private final class FakeHealthSource: HealthDataSource {
    var steps = 0
    var shouldThrow = false
    private(set) var totalCalls = 0

    var isAvailable: Bool { true }
    func requestAuthorization() async {}
    func total(from start: Date, to end: Date) async throws -> Int {
        totalCalls += 1
        if shouldThrow { throw CocoaError(.fileReadNoPermission) }
        return steps
    }
    func startObserving(onUpdate: @escaping @Sendable (_ done: @escaping @Sendable () -> Void) -> Void) async {}
}

/// F01-R6 설정 변경 흐름, F02 갱신 흐름, F06 표시 스냅샷
@MainActor
struct AppModelTests {

    private func makeStore() -> SharedStore {
        SharedStore(defaults: UserDefaults(suiteName: "AppModelTests-\(UUID().uuidString)")!)
    }

    @Test func refreshStoresSnapshot() async {
        let store = makeStore()
        let health = FakeHealthSource()
        health.steps = 6_240
        let model = AppModel(store: store, health: health)

        await model.refresh()

        #expect(model.snapshot?.value == 6_240)
        #expect(model.snapshot?.stage == 6)
        #expect(store.progressSnapshot == model.snapshot)
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
}
