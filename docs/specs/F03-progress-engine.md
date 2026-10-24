# F03. 진행률 엔진

- 상태: Built
- 담당: ios-dev
- 관련 스펙: F02(입력), F04(stageCount), F05·F06(소비), [DATA_MODEL](DATA_MODEL.md)
- 마지막 수정: 2026-10-24

## 목적
(현재 값, 목표, 기간, 테마 단계 수) → (진행률, 단계)를 계산하는 단일 순수 함수. 앱과 위젯은 이 결과만 쓴다.

## 요구사항
| ID | 요구사항 | 우선순위 |
|---|---|---|
| F03-R1 | `progress = min(value / target, 1.0)`, target ≤ 0 이면 0 | Must |
| F03-R2 | `stage = floor(progress * (stageCount - 1))`, 단 progress == 1.0 이면 stage = stageCount - 1 | Must |
| F03-R3 | 일간: 매일 로컬 00:00 리셋 | Must |
| F03-R4 | 주간: **매주 일요일 로컬 00:00 리셋**. 기기 로케일의 `firstWeekday`와 상관없이, 주입된 Calendar의 복사본에 `firstWeekday = 1`(일요일)을 설정해 계산 | Must |
| F03-R5 | 기준 시각·Calendar를 파라미터로 주입 (테스트 가능) | Must |
| F03-R6 | 100% 이상이면 `isComplete = true` | Must |
| F03-R7 | 주간 일평균 목표: `dailyAverageTarget = ceil(weeklyTarget / 7)` (F06-R8). 표시용이며 stage에는 영향 없음 | Must |
| F03-R8 | 입력 값은 지표와 무관한 숫자로 다룬다 (걸음·분 모두 같은 식). v0.2 지표 추가 시 엔진은 바뀌지 않는다 | Must |

## 동작 상세
- 예: stageCount=11, target=10,000
  - 0보 → stage 0 / 999보 → 0 / 1,000보 → 1 / 9,999보 → 9 / 10,000보 → 10
- 단계 경계: **floor 사용** (1% 모자라도 다음 단계로 안 넘어감 → 달성감 보존)
- 목표를 초과해도 stage는 마지막 단계에 고정. 초과분은 텍스트로만 표시 (예: "12,300 / 10,000 🎉")
- 주간 목표에서 "오늘까지 이상적인 페이스"는 보여주지 않는다. 이미지가 메인이고, 수치는 작은 텍스트로만.
- 출력은 [DATA_MODEL](DATA_MODEL.md) §2 `ProgressSnapshot`의 계산 필드(periodStart, periodEnd, progress, stage, isComplete).

## 수용 기준 (단위 테스트)
- [x] 위 예시 값 전부
- [x] 자정 직전(23:59:59)/직후(00:00:00)에 기간이 바뀐다
- [x] 주간: 토요일 23:59:59 → 일요일 00:00:00에 기간이 바뀐다
- [x] 주간: 로케일의 주 시작이 일요일(en_US)인 기기와 월요일(en_GB 등)인 기기 모두 일요일에 리셋된다
- [x] 서머타임 전환일(23시간/25시간짜리 날)에도 하루로 계산
- [x] target=0, value 음수, stageCount=1 같은 비정상 입력에서 크래시하지 않음
- [x] `dailyAverageTarget(70_000) == 10_000`, `dailyAverageTarget(50_000) == 7_143`

## 열린 질문
(없음)

## 변경 이력
- 2026-10-24: 최초 작성
- 2026-10-24: 열린 질문 1차 답변 완료
- 2026-10-24: 주간 리셋을 로케일 기준에서 일요일 고정으로 변경(R4). 일평균 목표(R7), 지표 무관 계산(R8) 추가
- 2026-10-24: Shared/ProgressEngine.swift 구현, 단위 테스트(GOOALLTests/ProgressEngineTests.swift) 전부 통과 → Built
