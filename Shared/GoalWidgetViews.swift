import SwiftUI
import WidgetKit

/// 위젯 화면 (F05). 위젯 타깃과 앱(렌더 테스트 등)이 함께 쓴다. 데이터는 스냅샷만 받는다 (F05-R4).
struct GoalWidgetContent: View {
    let snapshot: ProgressSnapshot?
    let family: WidgetFamily

    var body: some View {
        if let snapshot {
            let theme = ThemeRegistry.resolvedTheme(id: snapshot.themeID)
            switch family {
            case .accessoryRectangular:
                LockScreenGoalView(snapshot: snapshot, theme: theme)
            case .systemMedium:
                HomeGoalView(snapshot: snapshot, theme: theme, size: .medium)
            default:
                HomeGoalView(snapshot: snapshot, theme: theme, size: .large)
            }
        } else {
            EmptyGoalWidgetView(family: family)
        }
    }
}

/// systemLarge / systemMedium: 이미지가 꽉 차고 수치를 오버레이 (F05-R1, R2, R6, R9)
struct HomeGoalView: View {
    let snapshot: ProgressSnapshot
    let theme: Theme
    let size: ThemeImageSize

    var body: some View {
        StageImageView(theme: theme, stage: snapshot.stage, size: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(alignment: theme.overlay == .top ? .top : .bottom) {
                if theme.overlay != .none {
                    overlay
                }
            }
    }

    private var overlay: some View {
        VStack(spacing: 2) {
            // Medium은 높이가 낮아 완료 문구는 Large에서만
            if snapshot.isComplete && size == .large {
                Text(theme.doneMessage)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 6) {
                if snapshot.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                }
                Text("\(snapshot.value.formatted()) / \(snapshot.target.formatted())")
                    .monospacedDigit()
            }
            .font(.system(size: size == .large ? 20 : 16, weight: .black, design: .rounded))
        }
        .foregroundStyle(Color(hex: theme.overlayTextColorHex))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        // 이미지 밝기와 상관없이 라이트/다크 모두 읽히도록 반투명 배경을 깐다
        .background(.black.opacity(0.55), in: .capsule)
        .padding(size == .large ? 14 : 10)
    }
}

/// accessoryRectangular: 테마 이름 + 게이지 + 수치, 이미지 없음 (F05-R3)
struct LockScreenGoalView: View {
    let snapshot: ProgressSnapshot
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(theme.displayName)
                    .font(.headline)
                    .widgetAccentable()
                if snapshot.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                }
            }
            Gauge(value: snapshot.progress) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            Text("\(snapshot.value.formatted()) / \(snapshot.target.formatted())")
                .font(.caption)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 스냅샷이 없을 때 (F05-R8)
struct EmptyGoalWidgetView: View {
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: family == .accessoryRectangular ? .leading : .center, spacing: 6) {
            if family != .accessoryRectangular {
                Text(AppConstants.appName)
                    .font(.system(size: 28, weight: .black, design: .rounded))
            }
            Text("Hey, open \(AppConstants.appName) to set me up 👋")
                .font(family == .accessoryRectangular ? .caption : .headline)
                .multilineTextAlignment(family == .accessoryRectangular ? .leading : .center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

nonisolated extension ProgressSnapshot {
    /// 위젯 갤러리·Preview·렌더 테스트용 샘플
    static func sample(themeID: String = ThemeRegistry.defaultThemeID, stage: Int, now: Date = .now) -> ProgressSnapshot {
        let theme = ThemeRegistry.resolvedTheme(id: themeID)
        let settings = GoalSettings(metric: .steps, period: .daily, target: 10_000, themeID: theme.id)
        let value = theme.lastStage > 0 ? settings.target * stage / theme.lastStage : 0
        return ProgressEngine.makeSnapshot(
            value: value,
            todayValue: value,
            settings: settings,
            stageCount: theme.stageCount,
            now: now,
            calendar: .current
        )
    }
}
