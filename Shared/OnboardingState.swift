import Foundation

/// DATA_MODEL §3. 순서는 F01-R1.
nonisolated enum OnboardingStep: String, Codable, Sendable, CaseIterable {
    case intro, theme, goal, health, widgetGuide
}

nonisolated struct OnboardingState: Codable, Equatable, Sendable {
    var currentStep: OnboardingStep
    var isCompleted: Bool

    static let initial = OnboardingState(currentStep: .intro, isCompleted: false)
}
