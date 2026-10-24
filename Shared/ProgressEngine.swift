import Foundation

/// 진행률·단계·기간 계산의 유일한 위치 (CLAUDE.md 핵심 규칙 1, F03).
/// 순수 함수만 둔다. 기준 시각과 Calendar는 항상 주입받는다 (F03-R5).
nonisolated enum ProgressEngine {

    /// F03-R1. target ≤ 0이면 0, 음수 값은 0으로 본다.
    static func progress(value: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(Double(max(value, 0)) / Double(target), 1.0)
    }

    /// F03-R2. floor(progress * (stageCount - 1))를 정수 연산으로 계산해 부동소수 오차를 피한다.
    static func stage(value: Int, target: Int, stageCount: Int) -> Int {
        guard target > 0, stageCount > 1 else { return 0 }
        let clamped = min(max(value, 0), target)
        return clamped * (stageCount - 1) / target
    }

    /// F03-R6
    static func isComplete(value: Int, target: Int) -> Bool {
        target > 0 && value >= target
    }

    /// F03-R3, F03-R4. 일간은 로컬 자정, 주간은 로케일과 무관하게 일요일 자정부터.
    static func periodInterval(for period: GoalPeriod, at date: Date, calendar: Calendar) -> DateInterval {
        switch period {
        case .daily:
            return calendar.dateInterval(of: .day, for: date)!
        case .weekly:
            var sundayFirst = calendar
            sundayFirst.firstWeekday = 1
            return sundayFirst.dateInterval(of: .weekOfYear, for: date)!
        }
    }

    /// F03-R7. ceil(weeklyTarget / 7)
    static func dailyAverageTarget(weeklyTarget: Int) -> Int {
        guard weeklyTarget > 0 else { return 0 }
        return (weeklyTarget + 6) / 7
    }

    static func makeSnapshot(
        value: Int,
        todayValue: Int,
        settings: GoalSettings,
        stageCount: Int,
        now: Date,
        calendar: Calendar
    ) -> ProgressSnapshot {
        let interval = periodInterval(for: settings.period, at: now, calendar: calendar)
        return ProgressSnapshot(
            metric: settings.metric,
            period: settings.period,
            periodStart: interval.start,
            periodEnd: interval.end,
            value: value,
            todayValue: settings.period == .daily ? value : todayValue,
            target: settings.target,
            themeID: settings.themeID,
            stageCount: stageCount,
            progress: progress(value: value, target: settings.target),
            stage: stage(value: value, target: settings.target, stageCount: stageCount),
            isComplete: isComplete(value: value, target: settings.target),
            updatedAt: now
        )
    }

    /// 위젯 타임라인용 스냅샷 (F05-R5): [지금 보여줄 상태, 다음 리셋 시점의 0 상태].
    /// 저장된 스냅샷의 기간이 이미 지났으면(앱이 오래 안 열림) 지금 기간의 0 상태로 맞춘다.
    static func timelineSnapshots(from snapshot: ProgressSnapshot, now: Date, calendar: Calendar) -> [ProgressSnapshot] {
        var current = snapshot
        if now >= current.periodEnd {
            current = resetSnapshot(after: current, calendar: calendar)
            if now >= current.periodEnd {
                current = makeSnapshot(
                    value: 0,
                    todayValue: 0,
                    settings: GoalSettings(metric: current.metric, period: current.period, target: current.target, themeID: current.themeID),
                    stageCount: current.stageCount,
                    now: now,
                    calendar: calendar
                )
            }
        }
        return [current, resetSnapshot(after: current, calendar: calendar)]
    }

    /// 위젯 리셋 엔트리 (F05-R5): 다음 기간 시작 시점의 0 상태.
    static func resetSnapshot(after snapshot: ProgressSnapshot, calendar: Calendar) -> ProgressSnapshot {
        let settings = GoalSettings(
            metric: snapshot.metric,
            period: snapshot.period,
            target: snapshot.target,
            themeID: snapshot.themeID
        )
        return makeSnapshot(
            value: 0,
            todayValue: 0,
            settings: settings,
            stageCount: snapshot.stageCount,
            now: snapshot.periodEnd,
            calendar: calendar
        )
    }
}
