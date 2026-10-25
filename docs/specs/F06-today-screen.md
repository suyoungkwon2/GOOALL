# F06. 오늘 화면

- 상태: Ready
- 담당: ios-dev
- 관련 스펙: F02, F03, F04, [DATA_MODEL](DATA_MODEL.md)
- 마지막 수정: 2026-10-24

## 목적
앱을 열었을 때 위젯과 같은 그림을 크게 보여주고, 설정으로 가는 입구가 된다. 앱스토어 심사에서 "위젯만 있는 앱"으로 보이지 않게 하는 최소한의 본체.

## 요구사항
| ID | 요구사항 | 우선순위 |
|---|---|---|
| F06-R1 | 현재 단계 이미지를 화면 상단 대부분에 표시 | Must |
| F06-R2 | 현재 값 / 목표, 남은 양, 기간(오늘/이번 주) 표시 | Must |
| F06-R3 | 설정(테마, 목표) 진입 버튼 | Must |
| F06-R4 | 단계 미리보기: 슬라이더로 0~마지막 단계를 훑어볼 수 있다 (테마가 어떻게 변하는지 보는 재미) | Should |
| F06-R5 | 권한 안내 상태 (F02 참고). 권한을 요청한 적이 없으면 요청 버튼, 요청했는데 오늘 0이면 설정 이동 버튼 | Must |
| F06-R6 | 당겨서 새로고침 | Should |
| F06-R7 | 100% 달성 시 간단한 축하 연출 + 테마 `doneMessage` | Could |
| F06-R8 | 주간 목표일 때 두 줄 표시: ① 이번 주 합계 / 주간 목표 ② 오늘 걸음 수 / 일평균 목표(`dailyAverageTarget`, F03-R7). 지난 날의 이력(요일별 막대 등)은 보여주지 않는다 | Must |
| F06-R9 | 0단계일 때 테마의 `startMessage`를 표시 | Should |

## 동작 상세
- 이미지와 단계는 주간 합계 기준이다. 오늘/일평균 줄(R8 ②)은 참고용 텍스트이며 단계에 영향 없음.
- 수치는 작은 텍스트로 간략히. 이미지가 메인.
- 저장된 스냅샷의 기간이 지났으면(자정을 넘김, 갱신 실패) 위젯과 같은 규칙으로 현재 기간 0 상태를 보여준다. 앱이 켜진 채 날짜가 바뀌면 즉시 갱신한다.

## 문구 (영어, F01 톤)
- 기간 라벨: Today / This week
- 남은 양: {n} steps to go / 완료 후: Goal crushed 🎉
- 주간 ② 줄: Today {todayValue} / avg goal {dailyAverageTarget}
- 권한 안내 (R5, 단정하지 않기): Hmm, I'm seeing 0 steps. If Health access is off, you can turn it on in Settings.
- 권한 안내 버튼: Open Settings
- 권한을 아직 요청하지 않은 경우(온보딩에서 "Maybe later"): Wanna see your real steps? Let me peek at Health. / 버튼: Turn it on (누르면 권한 요청)
- 미리보기 중 현재 단계로 돌아가기 버튼: Back to now
- 단계 미리보기 라벨: Sneak peek

## 데이터
`ProgressSnapshot`(읽기), `GoalSettings`(읽기) → [DATA_MODEL](DATA_MODEL.md) §1, §2.

## 수용 기준
- [x] 위젯과 같은 시점에 같은 단계 이미지를 보여준다 (불일치 없음) — 앱·위젯 모두 `ProgressEngine.timelineSnapshots`로 현재 엔트리 선택 (AppModelTests)
- [x] 단계 미리보기는 실제 진행 값/스냅샷을 바꾸지 않는다
- [x] 가장 작은 기기와 가장 큰 기기에서 레이아웃이 깨지지 않는다 (iPhone 17e·17 Pro Max 시뮬레이터, 주간·핑크 배경)
- [x] 주간 목표일 때 주간 줄과 오늘/일평균 줄이 모두 나오고, 일간 목표일 때는 한 줄만 나온다

## 열린 질문
(없음)

## 변경 이력
- 2026-10-24: 최초 작성
- 2026-10-24: 주간 목표 시 일평균 목표·오늘 값 표시 추가(R8), 히스토리 미표시 확정. 0단계 응원 문구(R9), 영어 문구 추가
- 2026-10-24: 구현(GOOALL/TodayView.swift). 권한 미요청 상태 안내·"Turn it on" 버튼, "Back to now" 문구 추가(R5)
- 2026-10-24: QA 반영 — 기간 지난 스냅샷을 0으로 표시(위젯과 일치), 날짜 변경 시 갱신
- 2026-10-24: 그림 카드 배경을 위젯 배경 색과 동일하게 (F07-R6)
- 2026-10-25: 수용 기준 확인 — 위젯과 같은 엔트리(테스트), 17e·Pro Max 레이아웃(스크린샷)
