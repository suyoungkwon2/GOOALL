# 데이터 모델 (공용)

- 상태: Ready
- 담당: ios-dev (정의·저장소), widget-dev (읽기)
- 관련 스펙: F01(GoalSettings·OnboardingState), F02(ProgressSnapshot 생성), F03(계산), F04(Theme), F05·F06(소비)
- 마지막 수정: 2026-10-24

앱·위젯이 공유하는 모델의 원본. 각 기능 스펙은 여기를 링크만 한다. 모든 타입은 `Shared/`에 두고 `Codable, Equatable, Sendable`로 만든다 (Swift 6 전환 대비).

## 1. 목표 설정 — `GoalSettings`
```swift
enum GoalMetric: String, Codable, Sendable, CaseIterable {
    case steps
    // v0.2 후보: exerciseMinutes, sleepMinutes — 케이스만 추가하면 되도록 metric별 분기는 한 곳(MetricDescriptor)에 모은다
}

enum GoalPeriod: String, Codable, Sendable, CaseIterable {
    case daily, weekly
}

struct GoalSettings: Codable, Equatable, Sendable {
    var metric: GoalMetric      // MVP: 항상 .steps
    var period: GoalPeriod
    var target: Int             // metric 단위 (steps = 걸음)
    var themeID: String         // ThemeRegistry의 id
}
```
- 기본값: `metric = .steps`, `period = .daily`, `target = 10_000`, `themeID = "sixpack"`
- 지표별 기본값·허용 범위·단위 문구는 `MetricDescriptor`(metric → 기본값/범위/단위) 한 곳에 정의한다. 값은 F01-R5, F01-R8이 원본.
- 저장된 `themeID`가 레지스트리에 없거나 잠겨 있으면(F04-R7) 기본 테마 `sixpack`으로 대체한다.

## 2. 진행 스냅샷 — `ProgressSnapshot`
F02가 만들고 F05·F06이 읽는다. 계산 결과 필드는 반드시 `ProgressEngine`(F03)이 채운다.
```swift
struct ProgressSnapshot: Codable, Equatable, Sendable {
    var metric: GoalMetric
    var period: GoalPeriod
    var periodStart: Date       // 일간: 오늘 00:00 / 주간: 이번 주 일요일 00:00
    var periodEnd: Date         // 다음 리셋 시각 (위젯 리셋 엔트리 시각)
    var value: Int              // 기간 합계
    var todayValue: Int         // 오늘 합계. 일간이면 value와 같음
    var target: Int
    var themeID: String
    var stageCount: Int
    var progress: Double        // 0.0...1.0 (F03-R1)
    var stage: Int              // 0..<stageCount (F03-R2)
    var isComplete: Bool        // F03-R6
    var updatedAt: Date         // HealthKit에서 마지막으로 읽은 시각
}
```
- 주간 일평균 목표(F06-R8)는 저장하지 않고 `ProgressEngine.dailyAverageTarget(weeklyTarget:)`로 계산한다 (F03-R7).
- 위젯의 리셋 엔트리(F05-R5)는 `value = 0, todayValue = 0`으로 ProgressEngine을 다시 호출해 만든다.

## 3. 온보딩 상태 — `OnboardingState`
```swift
enum OnboardingStep: String, Codable, Sendable, CaseIterable {
    case intro, theme, goal, health, widgetGuide
}

struct OnboardingState: Codable, Equatable, Sendable {
    var currentStep: OnboardingStep   // 중단 후 재개 지점 (F01 수용 기준)
    var isCompleted: Bool
}
```

## 4. 테마 — `Theme`
`ThemeRegistry`(F04)가 정적 배열로 제공한다. UserDefaults에 저장하지 않는다.
```swift
enum OverlayPosition: String, Codable, Sendable { case bottom, top, none }

enum ThemeAccess: Codable, Equatable, Sendable {
    case free
    case paid(productID: String)      // v0.2 1회 구매용. MVP에서는 모든 테마가 .free
}

struct Theme: Identifiable, Equatable, Sendable {
    let id: String                    // 파일 접두어와 동일 (docs/DESIGN_HANDOFF.md)
    let displayName: String           // "Six-Pack"
    let tagline: String               // "Belly era → Six-pack era"
    let stageCount: Int               // 기본 11
    let overlay: OverlayPosition
    let overlayTextColorHex: String   // "#FFFFFF"
    let startMessage: String          // 0단계 응원 문구
    let doneMessage: String           // 100% 달성 문구
    let access: ThemeAccess
    let artStyle: ArtStyle            // .lineArt | .fullColor (F07-R3/R4)
}
```
- 이미지 이름은 저장하지 않고 규칙으로 만든다: `"<id>_<size>_<stage 2자리>"` (`ThemeRegistry.imageName(theme:size:stage:)`).

## 5. 저장소 — `SharedStore`
App Group `group.com.mel.GOOALL`의 `UserDefaults(suiteName:)`에 JSON(`JSONEncoder`, 날짜 `.secondsSince1970`)으로 저장. 키는 한 곳(`StoreKey` enum)에서만 정의한다.

| 키 | 타입 | 쓰는 쪽 | 읽는 쪽 |
|---|---|---|---|
| `goalSettings` | GoalSettings | 앱 | 앱, 위젯 |
| `progressSnapshot` | ProgressSnapshot | 앱(포그라운드·백그라운드 전달) | 앱, 위젯 |
| `onboardingState` | OnboardingState | 앱 | 앱 |
| `healthAuthRequested` | Bool | 앱 | 앱 (F02 권한 안내 판단) |
| `widgetAppearance` | WidgetAppearance | 앱 | 앱, 위젯 (F07, 없거나 깨지면 Auto) |
| `schemaVersion` | Int (현재 1) | 앱 | 앱 (향후 마이그레이션용) |
| `debugMockSteps` | Int? | 앱 (DEBUG 빌드만) | 앱 (DEBUG 빌드만) |

- 디코딩 실패·키 없음은 크래시 없이 `nil`로 처리한다 (위젯은 F05-R8 안내 상태, 앱은 온보딩).
- 앱을 삭제하면 App Group 데이터도 지워지므로 재설치 시 온보딩이 다시 나온다 (F01 수용 기준).
- v0.2 구매 내역은 StoreKit 2의 `Transaction.currentEntitlements`가 원본이다. 여기에 별도로 저장하지 않는다.

## 6. 위젯 배경 — `WidgetAppearance` (F07)
```swift
nonisolated struct WidgetAppearance: Codable, Equatable, Sendable {
    var backgroundID: String   // "system"(Auto) 또는 WidgetBackgrounds.presets의 id
}
```
- 색 목록·선 색 계산은 `Shared/WidgetAppearance.swift`의 `WidgetBackgrounds` 한 곳. 화면에는 `StageColors`(배경·선 색)를 environment로 내려준다.

## 변경 이력
- 2026-10-24: 최초 작성 (F01~F06 열린 질문 정리에 맞춰 공용 모델 정의)
- 2026-10-24: F07 반영 — Theme.artStyle, WidgetAppearance(§6), 저장 키 widgetAppearance 추가
