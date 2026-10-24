import Foundation

/// 테마 잠금 여부를 판단하는 단일 지점 (F04-R7).
/// v0.2 유료화 때 StoreKit 2 `Transaction.currentEntitlements` 기반 구현으로 `ThemeAccess.policy`만 교체한다.
nonisolated protocol ThemeAccessPolicy: Sendable {
    func isUnlocked(_ theme: Theme) -> Bool
}

/// MVP: 모든 테마 무료.
nonisolated struct AllThemesUnlockedPolicy: ThemeAccessPolicy {
    func isUnlocked(_ theme: Theme) -> Bool { true }
}

nonisolated extension ThemeAccess {
    static let policy: any ThemeAccessPolicy = AllThemesUnlockedPolicy()
}
