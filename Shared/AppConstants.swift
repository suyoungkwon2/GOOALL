import Foundation

/// 앱·위젯 공용 상수. 표시 이름이 바뀔 수 있으므로 코드에서는 이 상수로만 참조한다.
nonisolated enum AppConstants {
    static let appName = "GOOALL"
    static let appGroupID = "group.com.mel.GOOALL"
    static let widgetKind = "GOOALLWidget"
    /// 위젯 탭 → 앱 오늘 화면 (F05-R7). 스킴은 GOOALL/Info.plist의 CFBundleURLTypes에 등록
    static let todayURL = URL(string: "gooall://today")!
    /// 개인정보 처리방침 (F01-R11). 저장소의 PRIVACY.md. 전용 웹 페이지가 생기면 여기만 바꾼다.
    static let privacyPolicyURL = URL(string: "https://github.com/suyoungkwon2/GOOALL/blob/main/PRIVACY.md")!
}
