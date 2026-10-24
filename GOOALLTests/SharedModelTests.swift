import Foundation
import Testing
@testable import GOOALL

struct GoalSettingsTests {

    @Test func defaults() {
        let steps = MetricDescriptor.for(.steps)
        #expect(steps.defaultTarget(for: .daily) == 10_000)
        #expect(steps.defaultTarget(for: .weekly) == 70_000)
        #expect(GoalSettings.default.target == 10_000)
        #expect(GoalSettings.default.themeID == "sixpack")
    }

    @Test func clampingOutOfRangeTargets() {
        let steps = MetricDescriptor.for(.steps)
        #expect(steps.clampedTarget(500, for: .daily) == (1_000, true))
        #expect(steps.clampedTarget(200_000, for: .daily) == (100_000, true))
        #expect(steps.clampedTarget(8_000, for: .daily) == (8_000, false))
        #expect(steps.clampedTarget(1_000, for: .weekly) == (5_000, true))
        #expect(steps.clampedTarget(600_000, for: .weekly) == (500_000, true))
    }
}

struct ThemeRegistryTests {

    private struct LockAllButDefault: ThemeAccessPolicy {
        func isUnlocked(_ theme: Theme) -> Bool { theme.id == ThemeRegistry.defaultThemeID }
    }

    @Test func mvpThemesAreRegisteredAndFree() {
        #expect(ThemeRegistry.all.map(\.id) == ["sixpack", "eyeglow"])
        #expect(ThemeRegistry.all.allSatisfy { $0.access == .free })
        #expect(ThemeRegistry.availableThemes().count == 2)
    }

    @Test func imageNames() {
        let sixpack = ThemeRegistry.theme(id: "sixpack")!
        #expect(ThemeRegistry.imageName(for: sixpack, size: .large, stage: 0) == "sixpack_large_00")
        #expect(ThemeRegistry.imageName(for: sixpack, size: .medium, stage: 10) == "sixpack_medium_10")
        #expect(ThemeRegistry.imageName(for: sixpack, size: .large, stage: 99) == "sixpack_large_10")
        #expect(ThemeRegistry.imageName(for: sixpack, size: .large, stage: -1) == "sixpack_large_00")
    }

    @Test func unknownOrLockedThemeFallsBackToDefault() {
        #expect(ThemeRegistry.resolvedTheme(id: "nope").id == "sixpack")
        #expect(ThemeRegistry.resolvedTheme(id: "eyeglow").id == "eyeglow")
        #expect(ThemeRegistry.resolvedTheme(id: "eyeglow", policy: LockAllButDefault()).id == "sixpack")
        #expect(ThemeRegistry.availableThemes(policy: LockAllButDefault()).map(\.id) == ["sixpack"])
    }
}

struct SharedStoreTests {

    private func makeStore() -> SharedStore {
        SharedStore(defaults: UserDefaults(suiteName: "GOOALLTests-\(UUID().uuidString)")!)
    }

    @Test func emptyStoreReturnsNil() {
        let store = makeStore()
        #expect(store.goalSettings == nil)
        #expect(store.progressSnapshot == nil)
        #expect(store.onboardingState == nil)
        #expect(store.healthAuthRequested == false)
        #expect(store.schemaVersion == nil)
    }

    @Test func roundTrip() {
        let store = makeStore()
        let settings = GoalSettings(metric: .steps, period: .weekly, target: 70_000, themeID: "eyeglow")
        let snapshot = ProgressEngine.makeSnapshot(
            value: 30_000, todayValue: 4_000, settings: settings, stageCount: 11,
            now: Date(timeIntervalSince1970: 1_793_000_000), calendar: Calendar(identifier: .gregorian)
        )
        store.goalSettings = settings
        store.progressSnapshot = snapshot
        store.onboardingState = OnboardingState(currentStep: .health, isCompleted: false)
        store.healthAuthRequested = true

        #expect(store.goalSettings == settings)
        #expect(store.progressSnapshot == snapshot)
        #expect(store.onboardingState?.currentStep == .health)
        #expect(store.healthAuthRequested)
        #expect(store.schemaVersion == SharedStore.currentSchemaVersion)

        store.progressSnapshot = nil
        #expect(store.progressSnapshot == nil)
    }

    @Test func corruptDataReturnsNil() {
        let store = makeStore()
        store.defaults.set(Data("not json".utf8), forKey: SharedStore.Key.goalSettings.rawValue)
        #expect(store.goalSettings == nil)
    }
}
