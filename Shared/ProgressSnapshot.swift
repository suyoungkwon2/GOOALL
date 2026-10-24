import Foundation

/// DATA_MODEL §2. 계산 필드는 반드시 ProgressEngine이 채운다.
nonisolated struct ProgressSnapshot: Codable, Equatable, Sendable {
    var metric: GoalMetric
    var period: GoalPeriod
    var periodStart: Date
    var periodEnd: Date
    var value: Int
    var todayValue: Int
    var target: Int
    var themeID: String
    var stageCount: Int
    var progress: Double
    var stage: Int
    var isComplete: Bool
    var updatedAt: Date
}
