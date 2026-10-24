import SwiftUI
import UIKit
import WidgetKit

/// 테마의 단계 그림 (배경 없이 그림만). 배경은 호출하는 쪽이 `stageColors.background`로 깐다 (F07).
/// 에셋이 없으면 PlaceholderStageView로 대체한다 (F04-R3).
struct StageImageView: View {
    let theme: Theme
    let stage: Int
    let size: ThemeImageSize
    @Environment(\.stageColors) private var colors

    var body: some View {
        if let image = UIImage(named: ThemeRegistry.imageName(for: theme, size: size, stage: stage)) {
            switch theme.artStyle {
            case .lineArt:
                // 투명 배경 선 그림을 배경에 맞는 단색으로 칠한다 (F07-R3)
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(colors.line)
            case .fullColor:
                Image(uiImage: image)
                    .resizable()
                    // 틴트/클리어 홈 화면에서도 이미지 색 유지
                    .widgetAccentedRenderingMode(.fullColor)
                    .scaledToFill()
            }
        } else {
            PlaceholderStageView(theme: theme, stage: stage)
        }
    }
}

/// 디자인 이미지가 오기 전까지 쓰는 텍스트 플레이스홀더 (CLAUDE.md 핵심 규칙 4): "Eye Glow 3"
struct PlaceholderStageView: View {
    let theme: Theme
    let stage: Int
    @Environment(\.stageColors) private var colors

    private var clampedStage: Int { min(max(stage, 0), theme.lastStage) }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(theme.displayName) \(clampedStage)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text("stage \(clampedStage) of \(theme.lastStage)")
                .font(.caption.weight(.semibold))
                .opacity(0.6)
        }
        .foregroundStyle(colors.line)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
