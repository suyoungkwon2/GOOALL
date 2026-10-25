# F01. 온보딩·목표 설정

- 상태: Ready
- 담당: ios-dev
- 관련 스펙: F02(권한), F03(목표 → 진행률), F04(테마 선택), [DATA_MODEL](DATA_MODEL.md)
- 마지막 수정: 2026-10-25

## 목적
처음 켠 사용자가 1분 안에 "목표 + 되고 싶은 모습"을 정하고 위젯을 추가할 수 있게 한다. 이후 설정 화면에서 언제든 바꿀 수 있다.

## 요구사항
| ID | 요구사항 | 우선순위 |
|---|---|---|
| F01-R1 | 온보딩 순서: 소개 → 테마 선택 → 목표 설정 → 건강 권한 → 위젯 추가 안내 | Must |
| F01-R2 | 테마 선택 화면에서 각 테마의 0단계/마지막 단계 이미지를 비교해서 보여준다 (동기 부여 훅) | Must |
| F01-R3 | ~~목표 지표: 걸음 수 또는 운동 시간(분) 중 하나~~ → F01-R9로 대체 | - |
| F01-R4 | 목표 기간: 일간 또는 주간 | Must |
| F01-R5 | 목표값 입력: 스텝퍼 + 직접 입력. 기본값 일간 10,000보 / 주간 70,000보. 스텝퍼 단위 일간 500보 / 주간 1,000보 | Must |
| F01-R6 | 설정 화면에서 테마·목표 변경 가능. 변경 즉시 위젯 반영 | Must |
| F01-R7 | 위젯 추가 방법 안내 화면 (홈 화면 길게 누르기 → + → 앱 이름 → Large) 이미지/일러스트 포함 | Should |
| F01-R8 | 목표값 허용 범위: 걸음 1,000~100,000 (일간) / 5,000~500,000 (주간) | Must |
| F01-R9 | MVP 목표 지표는 걸음 수 하나. 지표 선택 UI는 만들지 않는다. 단, 모델은 `GoalMetric`으로 두어 v0.2에 운동 시간·수면 시간을 추가할 수 있게 한다 (DATA_MODEL §1) | Must |
| F01-R10 | 모든 화면 문구는 영어. 아래 "화면 문구"를 그대로 쓰고, 코드에서는 String Catalog(`Localizable.xcstrings`)로 관리해 다국어 확장에 대비 | Must |
| F01-R11 | 설정 화면 맨 아래 About 섹션: 개인정보 처리방침 링크(`AppConstants.privacyPolicyURL`, 외부 브라우저로 열기) + 앱 버전 표시 (앱스토어 심사 필수 항목) | Must |

## 동작 상세
- 건강 권한을 거부해도 온보딩은 완료된다. 오늘 화면에 권한 안내와 설정 이동 버튼을 표시한다 (F06).
- 테마·목표를 바꾸면 현재 기간의 진행 값은 유지하고 단계만 재계산한다.
- 주간 목표는 **매주 일요일 00:00(로컬)에 새로 시작**한다 (F03-R4). 사용자 설정으로 바꾸는 건 v0.2.
- 로고: 임시로 볼드한 텍스트 로고 "GOOALL"을 쓴다.
- 테마 선택 화면에는 `ThemeRegistry`에 등록된 테마만 나온다 (F04-R8).
- 이미지·일러스트가 없는 자리는 텍스트 플레이스홀더로 표시한다 (테마: "Six-Pack 3"처럼 이름+단계, 위젯 안내: 필요한 그림 설명).
- 목표 화면에서 Next를 눌렀을 때 값이 범위 밖이면, 보정된 값과 안내를 먼저 보여주고 다시 누르면 넘어간다.

## 화면 문구 (톤: Gen Z 대상. 친절·깔끔보다 친구/언니처럼 장난스럽게. 건강 효과는 주장하지 않는다)
`{theme}` = 선택한 테마의 `displayName`

### 1. Intro
- 화면: 식스팩 0단계 → 마지막 단계로 바뀌는 위젯 이미지를 크게
- Title: **Walk it. Get it.**
- Body: Pick the look you want. Every step you take changes your home screen. Literally.
- Button: Let's go

### 2. Theme
- Title: **Okay, what's your vibe?**
- Body: Whatever you pick shows up on your widget. You can switch anytime, no pressure.
- 카드: 테마 `displayName` + `tagline`, 좌우로 밀면 0단계 → 마지막 단계 미리보기 (tagline은 F04 테마 목록)
- Button: Next

### 3. Goal
- Title: **Now pick your goal**
- 선택: Daily / Weekly + 걸음 수 입력
- Helper (Daily): Hit your goal and the {theme} is yours. Every. Single. Day.
- Helper (Weekly): Resets every Sunday. New week, new you.
- 범위 보정 안내 (Daily): Whoa, let's keep it between 1,000 and 100,000 steps. Fixed it for you 💅
- 범위 보정 안내 (Weekly): Whoa, let's keep it between 5,000 and 500,000 steps. Fixed it for you 💅
- Button: Next

### 4. Health (시스템 권한 팝업 직전)
- Title: **Can I peek at your steps?**
- Body: I only read your step count from Health. Read-only, and it never leaves your phone. Pinky promise 🤙
- Button: Sure, go ahead
- 작은 글씨 버튼: Maybe later

### 5. Widget guide
- Title: **Last step, and it's the big one!**
- Subtitle: Put me on your home screen.
- 단계: Long-press an empty spot → Tap + at the top left → Search "GOOALL" → Pick the big one
- 일러스트 자리: 실제 Large 위젯 미리보기(선택한 테마·배경 색) + 배경 색 선택 (F07-R5)
- Body: Bigger widget = bigger glow-up. Trust me.
- Button: Done

### 설정 화면
- 섹션: Theme / Goal / Widget (F07) / About
- About: "Privacy Policy" (링크) / "Version" (예: 1.0 (1))
- 백그라운드 갱신 안내 (F02): Your steps update about once an hour (iOS decides the exact timing). Open the app to refresh right away.

## 데이터
`GoalSettings`, `OnboardingState` → [DATA_MODEL](DATA_MODEL.md) §1, §3. App Group UserDefaults 키 `goalSettings`, `onboardingState`.

## 수용 기준
- [ ] 앱 삭제 후 재설치 시 온보딩이 다시 나온다
- [x] 온보딩 중 앱을 종료했다 다시 켜면 처음부터가 아니라 중단된 단계에서 재개된다 (AppModelTests)
- [x] 범위 밖 값을 입력하면 가까운 허용값으로 보정되고 안내 문구가 나온다 (SharedModelTests + 시뮬레이터)
- [ ] 설정에서 테마를 바꾸면 5초 안에 위젯이 새 테마로 바뀐다
- [x] 온보딩·설정 어디에도 운동 시간 등 걸음 수 외 지표 선택 UI가 없다
- [x] 화면 문구가 위 "화면 문구"와 일치하고 String Catalog에 들어 있다
- [x] 설정 화면에서 개인정보 처리방침 링크를 열 수 있다

## 열린 질문
(없음)

## 변경 이력
- 2026-10-24: 최초 작성
- 2026-10-24: 열린 질문 1차 작성
- 2026-10-24: MVP 지표를 걸음 수로 한정(R3 취소 → R9), 운동 시간 기본값·범위 삭제. 문구를 영어(Gen Z 친구 톤)로 확정(R10). 주간 시작을 일요일로 고정. 데이터 모델을 DATA_MODEL.md로 분리
- 2026-10-24: 구현(GOOALL/OnboardingView.swift, SettingsView.swift, GoalTargetField.swift, Localizable.xcstrings). 텍스트 플레이스홀더, Next 보정 동작 명시
- 2026-10-24: QA 반영 — 설정 화면을 열 때 주간 목표가 기본값으로 덮어써지던 버그 수정, 목표 숫자 입력이 키 입력마다 반영되도록 변경, 설정 변경 시 지난 기간 값을 옮기지 않음
- 2026-10-24: 위젯 안내 화면에 위젯 미리보기와 배경 색 선택 추가 (F07)
- 2026-10-25: F01-R11 추가 — 설정 About 섹션(개인정보 처리방침 링크, 버전). 처리방침 원문은 저장소 PRIVACY.md. 누락된 F07 문구를 String Catalog에 추가
