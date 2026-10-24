import Foundation
import Testing
@testable import GOOALL

/// F03 수용 기준
struct ProgressEngineTests {

    private func calendar(timeZone: String = "America/New_York", firstWeekday: Int = 1) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timeZone)!
        cal.firstWeekday = firstWeekday
        return cal
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0, in cal: Calendar) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    // MARK: - 진행률·단계 (F03-R1, R2, R6)

    @Test(arguments: [
        (0, 0), (999, 0), (1_000, 1), (9_999, 9), (10_000, 10), (12_300, 10),
    ])
    func stageExamples(value: Int, expectedStage: Int) {
        #expect(ProgressEngine.stage(value: value, target: 10_000, stageCount: 11) == expectedStage)
    }

    @Test func progressIsCappedAtOne() {
        #expect(ProgressEngine.progress(value: 5_000, target: 10_000) == 0.5)
        #expect(ProgressEngine.progress(value: 12_300, target: 10_000) == 1.0)
    }

    @Test func everyTenPercentBoundaryAdvancesStage() {
        for k in 0...10 {
            #expect(ProgressEngine.stage(value: k * 1_000, target: 10_000, stageCount: 11) == k)
        }
    }

    @Test func completion() {
        #expect(!ProgressEngine.isComplete(value: 9_999, target: 10_000))
        #expect(ProgressEngine.isComplete(value: 10_000, target: 10_000))
        #expect(ProgressEngine.isComplete(value: 12_300, target: 10_000))
    }

    @Test func abnormalInputsDoNotCrash() {
        #expect(ProgressEngine.progress(value: 100, target: 0) == 0)
        #expect(ProgressEngine.progress(value: -50, target: 10_000) == 0)
        #expect(ProgressEngine.progress(value: 100, target: -10) == 0)
        #expect(ProgressEngine.stage(value: 100, target: 0, stageCount: 11) == 0)
        #expect(ProgressEngine.stage(value: -50, target: 10_000, stageCount: 11) == 0)
        #expect(ProgressEngine.stage(value: 10_000, target: 10_000, stageCount: 1) == 0)
        #expect(ProgressEngine.stage(value: 10_000, target: 10_000, stageCount: 0) == 0)
        #expect(!ProgressEngine.isComplete(value: 0, target: 0))
    }

    // MARK: - 기간 (F03-R3, R4)

    @Test func dailyPeriodChangesAtMidnight() {
        let cal = calendar()
        let before = ProgressEngine.periodInterval(for: .daily, at: date(2026, 10, 24, 23, 59, 59, in: cal), calendar: cal)
        let after = ProgressEngine.periodInterval(for: .daily, at: date(2026, 10, 25, 0, 0, 0, in: cal), calendar: cal)
        #expect(before.start == date(2026, 10, 24, in: cal))
        #expect(before.end == date(2026, 10, 25, in: cal))
        #expect(after.start == date(2026, 10, 25, in: cal))
    }

    @Test func weeklyPeriodChangesSaturdayToSunday() {
        let cal = calendar()
        // 2026-10-24는 토요일
        let saturday = ProgressEngine.periodInterval(for: .weekly, at: date(2026, 10, 24, 23, 59, 59, in: cal), calendar: cal)
        let sunday = ProgressEngine.periodInterval(for: .weekly, at: date(2026, 10, 25, 0, 0, 0, in: cal), calendar: cal)
        #expect(saturday.start == date(2026, 10, 18, in: cal))
        #expect(saturday.end == date(2026, 10, 25, in: cal))
        #expect(sunday.start == date(2026, 10, 25, in: cal))
    }

    @Test(arguments: [1, 2]) // 1 = 일요일 시작(en_US), 2 = 월요일 시작(en_GB 등)
    func weeklyAlwaysStartsSundayRegardlessOfLocale(firstWeekday: Int) {
        let cal = calendar(firstWeekday: firstWeekday)
        let monday = date(2026, 10, 26, 9, in: cal)
        let interval = ProgressEngine.periodInterval(for: .weekly, at: monday, calendar: cal)
        #expect(interval.start == date(2026, 10, 25, in: cal))
        #expect(interval.end == date(2026, 11, 1, in: cal))
    }

    @Test func dstDaysCountAsOneDay() {
        let cal = calendar()
        let springForward = ProgressEngine.periodInterval(for: .daily, at: date(2026, 3, 8, 12, in: cal), calendar: cal)
        let fallBack = ProgressEngine.periodInterval(for: .daily, at: date(2026, 11, 1, 12, in: cal), calendar: cal)
        #expect(springForward.start == date(2026, 3, 8, in: cal))
        #expect(springForward.duration == 23 * 3600)
        #expect(fallBack.start == date(2026, 11, 1, in: cal))
        #expect(fallBack.duration == 25 * 3600)
    }

    // MARK: - 일평균 목표 (F03-R7)

    @Test func dailyAverageTarget() {
        #expect(ProgressEngine.dailyAverageTarget(weeklyTarget: 70_000) == 10_000)
        #expect(ProgressEngine.dailyAverageTarget(weeklyTarget: 50_000) == 7_143)
        #expect(ProgressEngine.dailyAverageTarget(weeklyTarget: 0) == 0)
    }

    // MARK: - 스냅샷

    @Test func dailySnapshotUsesValueAsTodayValue() {
        let cal = calendar()
        let now = date(2026, 10, 24, 15, in: cal)
        let snapshot = ProgressEngine.makeSnapshot(
            value: 6_240, todayValue: 999, settings: .default, stageCount: 11, now: now, calendar: cal
        )
        #expect(snapshot.todayValue == 6_240)
        #expect(snapshot.stage == 6)
        #expect(!snapshot.isComplete)
        #expect(snapshot.periodEnd == date(2026, 10, 25, in: cal))
        #expect(snapshot.updatedAt == now)
    }

    @Test func weeklyResetSnapshotStartsAtNextSunday() {
        let cal = calendar()
        let settings = GoalSettings(metric: .steps, period: .weekly, target: 70_000, themeID: "eyeglow")
        let snapshot = ProgressEngine.makeSnapshot(
            value: 70_000, todayValue: 12_000, settings: settings, stageCount: 11,
            now: date(2026, 10, 24, 20, in: cal), calendar: cal
        )
        #expect(snapshot.isComplete)
        #expect(snapshot.todayValue == 12_000)

        let reset = ProgressEngine.resetSnapshot(after: snapshot, calendar: cal)
        #expect(reset.value == 0)
        #expect(reset.todayValue == 0)
        #expect(reset.stage == 0)
        #expect(reset.periodStart == date(2026, 10, 25, in: cal))
        #expect(reset.periodEnd == date(2026, 11, 1, in: cal))
        #expect(reset.themeID == "eyeglow")
    }
}
