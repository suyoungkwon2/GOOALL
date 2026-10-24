import SwiftUI

/// 걸음 수 목표 입력: 직접 입력 + 스텝퍼 (F01-R5). 포커스가 빠질 때 범위를 보정한다 (F01-R8).
struct GoalTargetField: View {
    let period: GoalPeriod
    @Binding var target: Int
    @Binding var showsAdjustNotice: Bool
    @FocusState private var isFocused: Bool

    private var descriptor: MetricDescriptor { .for(.steps) }

    var body: some View {
        VStack(spacing: 12) {
            // 키 입력마다 바로 반영 (숫자 키패드엔 Return이 없어 커밋 시점에 의존하지 않는다)
            TextField("Steps", text: Binding(
                get: { target.formatted() },
                set: { target = Int($0.filter(\.isNumber)) ?? 0 }
            ))
                .keyboardType(.numberPad)
                .focused($isFocused)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
            Text("steps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Stepper(
                "Steps",
                value: $target,
                in: descriptor.allowedRange(for: period),
                step: descriptor.stepperIncrement(for: period)
            )
            .labelsHidden()
            if showsAdjustNotice {
                GoalAdjustNotice(period: period)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { clamp() }
        }
        .onChange(of: target) { _, newValue in
            if descriptor.allowedRange(for: period).contains(newValue) { showsAdjustNotice = false }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFocused = false }
            }
        }
    }

    private func clamp() {
        let result = descriptor.clampedTarget(target, for: period)
        target = result.value
        if result.wasAdjusted { showsAdjustNotice = true }
    }
}

struct GoalAdjustNotice: View {
    let period: GoalPeriod

    var body: some View {
        let range = MetricDescriptor.for(.steps).allowedRange(for: period)
        Text("Whoa, let's keep it between \(range.lowerBound.formatted()) and \(range.upperBound.formatted()) steps. Fixed it for you 💅")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.orange)
            .multilineTextAlignment(.center)
    }
}
