import Foundation

nonisolated enum OverlayPosition: String, Codable, Sendable {
    case bottom, top, none
}

/// F04-R7. MVP에서는 모든 테마가 `.free`.
nonisolated enum ThemeAccess: Codable, Equatable, Sendable {
    case free
    case paid(productID: String)
}

/// 이미지 파일 이름의 size 부분 (docs/DESIGN_HANDOFF.md)
nonisolated enum ThemeImageSize: String, Sendable {
    case large, medium, lock
}

/// DATA_MODEL §4
nonisolated struct Theme: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let tagline: String
    let stageCount: Int
    let overlay: OverlayPosition
    let overlayTextColorHex: String
    let startMessage: String
    let doneMessage: String
    let access: ThemeAccess

    var lastStage: Int { max(stageCount - 1, 0) }
}
