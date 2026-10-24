import Foundation

/// 앱·위젯 공용 테마 목록 (F04-R2). 테마 추가는 `all`에 항목을 넣는 것뿐이다 — if/switch 추가 금지.
/// 선택 테마(F04-R8)는 이미지가 준비되면 `/add-theme`로 여기에 등록한다.
nonisolated enum ThemeRegistry {
    static let defaultThemeID = "sixpack"

    static let all: [Theme] = [
        Theme(
            id: "sixpack",
            displayName: String(localized: "Six-Pack"),
            tagline: String(localized: "Belly era → Six-pack era"),
            stageCount: 11,
            overlay: .bottom,
            overlayTextColorHex: "#FFFFFF",
            startMessage: String(localized: "Your six-pack's waiting. Let's get walking 🚶‍♀️"),
            doneMessage: String(localized: "Six-pack: unlocked. You ate that 🔥"),
            access: .free
        ),
        Theme(
            id: "eyeglow",
            displayName: String(localized: "Eye Glow"),
            tagline: String(localized: "Zombie eyes → Sparkly eyes"),
            stageCount: 11,
            overlay: .bottom,
            overlayTextColorHex: "#FFFFFF",
            startMessage: String(localized: "Sleepy eyes? Same. Let's wake them up 👀"),
            doneMessage: String(localized: "Eyes sparkling. Main character energy ✨"),
            access: .free
        ),
    ]

    static func theme(id: String) -> Theme? {
        all.first { $0.id == id }
    }

    /// 테마 선택 화면 등 목록을 보여주는 곳은 모두 이 함수를 거친다.
    static func availableThemes(policy: any ThemeAccessPolicy = ThemeAccess.policy) -> [Theme] {
        all.filter { policy.isUnlocked($0) }
    }

    /// 저장된 id가 없거나 잠겨 있으면 기본 테마로 대체한다 (F04 동작 상세).
    static func resolvedTheme(id: String, policy: any ThemeAccessPolicy = ThemeAccess.policy) -> Theme {
        if let theme = theme(id: id), policy.isUnlocked(theme) {
            return theme
        }
        return theme(id: defaultThemeID)!
    }

    /// `<themeID>_<size>_<stage 2자리>` (docs/DESIGN_HANDOFF.md). stage는 0...lastStage로 보정.
    static func imageName(for theme: Theme, size: ThemeImageSize, stage: Int) -> String {
        let clamped = min(max(stage, 0), theme.lastStage)
        return "\(theme.id)_\(size.rawValue)_\(String(format: "%02d", clamped))"
    }
}
