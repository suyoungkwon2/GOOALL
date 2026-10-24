import Foundation

/// 목표 지표. MVP는 걸음 수만 (F01-R9). v0.2에 exerciseMinutes, sleepMinutes 추가 예정.
nonisolated enum GoalMetric: String, Codable, Sendable, CaseIterable {
    case steps
}

nonisolated enum GoalPeriod: String, Codable, Sendable, CaseIterable {
    case daily, weekly
}

/// DATA_MODEL §1
nonisolated struct GoalSettings: Codable, Equatable, Sendable {
    var metric: GoalMetric
    var period: GoalPeriod
    var target: Int
    var themeID: String

    static let `default` = GoalSettings(
        metric: .steps,
        period: .daily,
        target: MetricDescriptor.for(.steps).defaultTarget(for: .daily),
        themeID: ThemeRegistry.defaultThemeID
    )
}

/// 지표별 기본값·허용 범위·스텝퍼 단위. 지표에 따른 분기는 이 타입 한 곳에만 둔다.
nonisolated struct MetricDescriptor: Sendable {
    let metric: GoalMetric
    private let defaults: [GoalPeriod: Int]
    private let ranges: [GoalPeriod: ClosedRange<Int>]
    private let increments: [GoalPeriod: Int]

    static func `for`(_ metric: GoalMetric) -> MetricDescriptor {
        switch metric {
        case .steps:
            // F01-R5, F01-R8
            MetricDescriptor(
                metric: .steps,
                defaults: [.daily: 10_000, .weekly: 70_000],
                ranges: [.daily: 1_000...100_000, .weekly: 5_000...500_000],
                increments: [.daily: 500, .weekly: 1_000]
            )
        }
    }

    func defaultTarget(for period: GoalPeriod) -> Int { defaults[period]! }
    func allowedRange(for period: GoalPeriod) -> ClosedRange<Int> { ranges[period]! }
    func stepperIncrement(for period: GoalPeriod) -> Int { increments[period]! }

    /// 범위 밖 값을 가까운 허용값으로 보정한다. `wasAdjusted`가 true면 UI가 안내 문구를 띄운다 (F01 수용 기준).
    func clampedTarget(_ value: Int, for period: GoalPeriod) -> (value: Int, wasAdjusted: Bool) {
        let range = allowedRange(for: period)
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return (clamped, clamped != value)
    }
}
