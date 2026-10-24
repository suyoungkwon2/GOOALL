import SwiftUI
import WidgetKit

/// F07 위젯 배경 색 설정. App Group 키 `widgetAppearance`.
nonisolated struct WidgetAppearance: Codable, Equatable, Sendable {
    var backgroundID: String

    static let `default` = WidgetAppearance(backgroundID: WidgetBackgrounds.systemID)
}

nonisolated struct BackgroundPreset: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let hex: String
}

/// 배경 색 목록과 색 계산 (F07). 색을 추가할 때는 `presets`에 항목만 넣는다.
nonisolated enum WidgetBackgrounds {
    static let systemID = "system"
    static let systemLightHex = "#FFFFFF"
    static let systemDarkHex = "#1C1C1E"

    static let presets: [BackgroundPreset] = [
        BackgroundPreset(id: "milk", displayName: String(localized: "Milk"), hex: "#FBF8F3"),
        BackgroundPreset(id: "cream", displayName: String(localized: "Cream"), hex: "#FFF1CC"),
        BackgroundPreset(id: "pink", displayName: String(localized: "Pink"), hex: "#FFD6E2"),
        BackgroundPreset(id: "sky", displayName: String(localized: "Sky"), hex: "#D3E8FF"),
        BackgroundPreset(id: "mint", displayName: String(localized: "Mint"), hex: "#CFF3E2"),
        BackgroundPreset(id: "lavender", displayName: String(localized: "Lavender"), hex: "#E5DBFF"),
        BackgroundPreset(id: "midnight", displayName: String(localized: "Midnight"), hex: "#33384F"),
    ]

    /// 배경 hex. 모르는 id는 Auto로 본다.
    static func backgroundHex(id: String, isDark: Bool) -> String {
        presets.first { $0.id == id }?.hex ?? (isDark ? systemDarkHex : systemLightHex)
    }

    /// 어두운 배경이면 흰 선 (F07-R3). 상대 휘도 0.5 기준.
    static func usesLightLines(onHex hex: String) -> Bool {
        relativeLuminance(hex: hex) < 0.5
    }

    static func relativeLuminance(hex: String) -> Double {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard digits.count == 6, let rgb = UInt32(digits, radix: 16) else { return 1 }
        func linear(_ component: UInt32) -> Double {
            let c = Double(component & 0xFF) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgb >> 16) + 0.7152 * linear(rgb >> 8) + 0.0722 * linear(rgb)
    }

    static func colors(id: String, colorScheme: ColorScheme) -> StageColors {
        let hex = backgroundHex(id: id, isDark: colorScheme == .dark)
        return StageColors(background: Color(hex: hex), line: usesLightLines(onHex: hex) ? .white : .black)
    }
}

/// 단계 그림을 그릴 때 쓰는 배경·선 색. 화면마다 environment로 내려준다.
struct StageColors {
    var background: Color
    var line: Color
}

extension EnvironmentValues {
    @Entry var stageColors = StageColors(background: .white, line: .black)
}

/// 배경 + 단계 그림 (앱 화면용, F07-R6). 위젯은 containerBackground로 배경을 깐다.
struct StageCard: View {
    let theme: Theme
    let stage: Int
    let size: ThemeImageSize
    let appearance: WidgetAppearance
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = WidgetBackgrounds.colors(id: appearance.backgroundID, colorScheme: colorScheme)
        StageImageView(theme: theme, stage: stage, size: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .background(colors.background)
            .environment(\.stageColors, colors)
    }
}

/// 앱 안에서 보여주는 위젯 모습 (온보딩 미리보기·렌더 테스트). 실제 위젯과 같은 화면 코드를 쓴다.
struct WidgetPreview: View {
    let snapshot: ProgressSnapshot?
    let family: WidgetFamily
    let appearance: WidgetAppearance
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = WidgetBackgrounds.colors(id: appearance.backgroundID, colorScheme: colorScheme)
        GoalWidgetContent(snapshot: snapshot, family: family)
            .background(colors.background)
            .environment(\.stageColors, colors)
            .foregroundStyle(colors.line)
    }
}
