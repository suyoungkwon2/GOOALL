# CLAUDE.md — 프로젝트 헌법

모든 에이전트는 작업 시작 전에 이 파일을 읽고, 작업과 관련된 `docs/specs/Fxx-*.md`를 읽는다.
(제품 개요: `docs/PRD.md` / 디자인 규격: `docs/DESIGN_HANDOFF.md` / 진행 상황: `docs/PROGRESS.md` / 테스트·CI: `docs/TEST_PLAN.md`)

## 프로젝트 설정값 (사용자가 채움 — 비어 있으면 임의로 정하지 말고 물어볼 것)
- 앱 이름: GOOALL (표시 이름은 바뀔 수 있으니 코드에서는 상수로만 참조)
- 번들 ID: 앱 `com.mel.GOOALL` / 위젯 `com.mel.GOOALL.widget`
- App Group ID: `group.com.mel.GOOALL` (앱·위젯 entitlements에 이미 설정됨)
- Xcode 타깃: `GOOALL`(앱), `widgetExtension`(위젯, 소스 폴더명은 `widget/`), `GOOALLTests`, `GOOALLUITests`
- 최소 iOS: 현재 26.0 
- 지원 언어: 영어 우선, mvp 이후 다국어 지원

## 앱 한 줄 요약
걸음 수 목표 달성률을 (운동 시간·수면 시간은 v0.2) 사용자가 고른 "모티베이션 테마"(식스팩, 맑은 안광 등)의 이미지 변화로 보여주는 iOS 앱. 메인 무대는 홈 화면 **Large 위젯**.
(앱 이름: GOOALL)

## 기술 스택 (변경 금지, 바꾸려면 사용자에게 먼저 물을 것)
- Swift 언어 모드 5 (Xcode 26 기본값: Swift Language Version = 5, Approachable Concurrency 켜짐, 앱 타깃 기본 격리 MainActor), SwiftUI, iOS 26 이상
  - 언어 모드를 Swift 6으로 바꾸지 말 것. `.claude/agents/`에 "Swift 6"이라고 적혀 있어도 이 규칙이 우선한다.
  - 동시성 코드는 Swift 6 모드로 옮기기 쉽게 작성한다 (`@MainActor`, `Sendable`, `async/await`, 공유 가변 상태 최소화). MVP 출시 후 타깃별로 6 전환을 검토한다.
- 디자인: Liquid Glass를 적극 사용 (표준 컨트롤은 자동 적용, 필요한 곳에 `.glassEffect` 등). 위젯 이미지는 틴트/클리어 홈 화면 모드에서도 색이 유지되는지 시뮬레이터로 확인 (`widgetAccentedRenderingMode` 검토)
- WidgetKit (홈 화면 systemLarge 우선, systemMedium·잠금화면 accessoryRectangular 보조)
- HealthKit: `stepCount` 읽기 전용 (v0.2에 `appleExerciseTime`, `sleepAnalysis` 추가 예정 → 지표 확장이 쉽게 `GoalMetric`/`HealthDataSource`로 추상화)
- 앱 내 문구: 영어, Gen Z 대상 친구/언니 톤. 문구 원본은 각 스펙의 "문구" 절, 코드는 String Catalog 사용
- 데이터 모델 원본: `docs/specs/DATA_MODEL.md`
- 앱 ↔ 위젯 데이터 공유: App Group + `UserDefaults(suiteName:)`
- 외부 라이브러리 사용 금지 (SPM 의존성 0개 유지). 서버·로그인·분석 SDK 없음.
- 빌드/실행/스크린샷: XcodeBuildMCP 사용

## 폴더 구조 (저장소 루트 = 이 파일이 있는 곳)
```
GOOALL/            앱 타깃 소스 (온보딩, 설정, 오늘 화면). Xcode 동기화 폴더 → 파일을 넣으면 앱 타깃에 자동 포함
widget/            위젯 타깃(widgetExtension) 소스. 동기화 폴더
Shared/            앱·위젯 공용 코드와 테마 에셋 (모델, ProgressEngine, 저장소, ThemeRegistry, Themes.xcassets)
GOOALLTests/       단위 테스트 (ProgressEngine 등)
Assets/Themes/     디자이너가 넘긴 원본 PNG (규칙은 docs/DESIGN_HANDOFF.md). 앱에 쓰는 건 /add-theme가 Shared로 등록
docs/  .claude/    스펙, 문서, 에이전트, 스킬
```
**Shared/**: 앱·위젯 두 타깃에 동기화 폴더로 연결 완료 (2026-10-24). 여기에 파일을 넣으면 두 타깃에 자동 포함된다. 에이전트가 .pbxproj를 직접 수정하지 않는다.

## 스펙 운영 규칙 (매우 중요)
1. 기능의 동작은 `docs/specs/`가 원본이다. 스펙이 **Ready**가 아니면(Draft) 구현을 시작하기 전에 "열린 질문"을 사용자에게 먼저 묻는다.
2. 동작이 바뀌는 코드를 바꿨다면, **같은 작업 안에서** `/update-spec`의 B절을 수행한다 (스펙 수정 + 변경 이력 + 상태/체크박스).
3. 코드와 스펙이 어긋나면 임의로 한쪽을 고치지 말고 사용자에게 어느 쪽이 맞는지 묻는다.
4. 스펙에 없는 기능을 추가하지 않는다. 필요하면 `/update-spec`의 A절로 먼저 스펙을 만든다.
5. 마일스톤이 끝날 때 qa가 `/update-spec`의 C절(불일치 점검)을 실행한다.

## 핵심 규칙
1. **진행률 계산은 `Shared/ProgressEngine.swift` 한 곳에서만.** 앱·위젯이 각자 계산하지 않는다.
2. **테마는 데이터로 추가한다.** 테마 이름·단계 수·파일 접두어는 `Shared/ThemeRegistry.swift`에 등록. 테마를 추가할 때 if/switch 문을 늘리지 않는다.
3. 위젯은 HealthKit을 직접 읽지 않는다. 앱/백그라운드 작업이 App Group에 저장한 스냅샷만 읽는다 (잠금 상태에서 HealthKit 접근이 막힐 수 있음).
4. 이미지가 아직 없으면 `PlaceholderStageView`(단계 번호 + 진행률 텍스트)를 보여준다. 디자인 대기 때문에 개발을 멈추지 않는다.
5. 건강 효과를 주장하는 문구 금지 ("탈모가 낫는다" 등). 톤은 "동기부여용 재미 시각화".
6. 성적·노골적 테마는 만들지 않는다 (앱스토어 가이드라인 1.1.4).
7. 작업 단위가 끝날 때마다 (스펙 갱신 포함): `scripts/ci.sh` 통과 → (화면 변경 시) 시뮬레이터 스크린샷 확인 → `docs/PROGRESS.md`에 한 줄 기록.
8. 동작이 바뀌는 코드에는 같은 작업에서 테스트를 추가·수정한다. GitHub Actions CI(`.github/workflows/ci.yml`)가 main push·PR마다 자동으로 같은 검사를 돌린다. CI가 실패한 상태로 다음 작업을 시작하지 않는다 (docs/TEST_PLAN.md).

## 에이전트 팀
| 에이전트 | 파일 | 담당 |
|---|---|---|
| pm (opus) | `.claude/agents/pm.md` | 작업 분해, 순서, 완료 기준, PROGRESS.md 관리 |
| ios-dev (sonnet) | `.claude/agents/ios-dev.md` | 앱 본체, 설정 UI, HealthKit, ProgressEngine |
| widget-dev (sonnet) | `.claude/agents/widget-dev.md` | WidgetKit, 타임라인, App Group |
| asset-integrator (haiku) | `.claude/agents/asset-integrator.md` | 디자인 이미지 검증·등록·매핑 |
| qa (sonnet) | `.claude/agents/qa.md` | 빌드, 스크린샷 검증, 테스트, 심사 체크 |

## 스킬
- `/update-spec` — 기능 스펙 작성·갱신·불일치 점검
- `/add-theme` — 새 모티베이션 테마 이미지 세트를 받아 등록
- `/release-check` — 출시 전 점검

## 사람이 직접 해야 하는 것 (에이전트는 대신 하지 말고 안내만)
Apple Developer 가입, Xcode 서명·Capabilities(HealthKit, App Group) 최초 설정, 디자인 이미지 제작, 스펙의 열린 질문 결정, 실기기 테스트, App Store Connect 제출. 전체 목록: `docs/USER_TODO.md`
