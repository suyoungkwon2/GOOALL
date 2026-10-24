import SwiftUI
import UIKit
import WidgetKit

/// 테마의 단계 이미지. 에셋이 없으면 PlaceholderStageView로 대체한다 (F04-R3).
struct StageImageView: View {
    let theme: Theme
    let stage: Int
    let size: ThemeImageSize

    var body: some View {
        if let image = UIImage(named: ThemeRegistry.imageName(for: theme, size: size, stage: stage)) {
            Image(uiImage: image)
                .resizable()
                // 틴트/클리어 홈 화면에서도 이미지 색 유지
                .widgetAccentedRenderingMode(.fullColor)
                .scaledToFill()
        } else {
            PlaceholderStageView(theme: theme, stage: stage)
        }
    }
}

/// 디자인 이미지가 오기 전까지 쓰는 텍스트 플레이스홀더 (CLAUDE.md 핵심 규칙 4): "Eye Glow 3"
struct PlaceholderStageView: View {
    let theme: Theme
    let stage: Int

    private var clampedStage: Int { min(max(stage, 0), theme.lastStage) }
    private var ratio: Double {
        theme.lastStage > 0 ? Double(clampedStage) / Double(theme.lastStage) : 1
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: 0.62 - 0.55 * ratio, saturation: 0.25 + 0.45 * ratio, brightness: 0.50 + 0.35 * ratio),
                    Color(hue: 0.70 - 0.55 * ratio, saturation: 0.35 + 0.45 * ratio, brightness: 0.35 + 0.40 * ratio),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 6) {
                Text("\(theme.displayName) \(clampedStage)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text("stage \(clampedStage) of \(theme.lastStage)")
                    .font(.caption.weight(.semibold))
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .padding()
        }
    }
}

/// 그림이 들어갈 자리(일러스트 등)를 텍스트로 표시한다.
struct IllustrationPlaceholder: View {
    let description: LocalizedStringKey

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.quaternary)
            .overlay {
                Text(description)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            }
    }
}
