# F02. 건강 데이터 수집

- 상태: Ready
- 담당: ios-dev
- 관련 스펙: F01(권한 요청 시점), F03(입력값), F05(스냅샷 소비), [DATA_MODEL](DATA_MODEL.md)
- 마지막 수정: 2026-10-24

## 목적
HealthKit에서 걸음 수를 읽어 현재 기간의 합계를 만들고, 위젯이 읽을 수 있게 App Group에 저장한다.

## 요구사항
| ID | 요구사항 | 우선순위 |
|---|---|---|
| F02-R1 | 읽기 권한만 요청: `stepCount`. 쓰기 권한 요청 없음. (운동 시간 `appleExerciseTime`·수면 `sleepAnalysis`는 v0.2에서 해당 지표를 추가할 때 함께 요청) | Must |
| F02-R2 | 현재 기간(일간=오늘 00:00~, 주간=이번 주 일요일 00:00~)의 합계를 `HKStatisticsQuery`로 계산. 주간이면 오늘 합계(`todayValue`)도 함께 계산 | Must |
| F02-R3 | 앱이 열릴 때 즉시 갱신 | Must |
| F02-R4 | `enableBackgroundDelivery(.hourly)` + `HKObserverQuery`로 앱이 꺼져 있어도 갱신 | Must |
| F02-R5 | 갱신 결과(`ProgressSnapshot`)를 App Group에 저장하고, **단계가 바뀐 경우에만** 위젯 reload | Must |
| F02-R6 | 아이폰 + 애플워치 데이터 중복 집계는 HealthKit의 통계 쿼리(소스 병합)에 맡긴다 | Must |
| F02-R7 | HealthKit 접근은 `HealthDataSource` 프로토콜 뒤에 둔다. MVP 구현은 걸음 수 하나, v0.2에 지표를 추가할 때 이 프로토콜 구현만 늘린다 | Must |
| F02-R8 | DEBUG 빌드 전용 "가짜 걸음 수" 슬라이더 (`debugMockSteps`). 값이 있으면 HealthKit 대신 이 값으로 스냅샷을 만든다. Release 빌드에서는 코드째 빠진다 (`#if DEBUG`) | Must |

## 동작 상세
- 권한 상태 3가지를 구분한다: 미요청 / 허용됨 / 거부됨. HealthKit은 읽기 권한 거부 여부를 앱에 직접 알려주지 않는다 — **데이터가 0이어서 거부로 보이는 경우와 실제 0을 구분할 수 없음**. 따라서 권한 안내는 "오늘 데이터가 0이고 권한 요청을 이미 한 경우(`healthAuthRequested`)"에 소프트하게 표시한다 (단정하지 않는 문구, F06).
- 갱신 주기는 **1시간**으로 확정. 1시간은 iOS가 걸음 수에 허용하는 최대 빈도이고, 보장이 아니다. 시스템은 배터리 상태, 저전력 모드, 기기 잠금 여부(잠긴 동안 건강 데이터는 암호화되어 있음), 사용자가 앱을 강제 종료했는지에 따라 전달을 늦추거나 건너뛸 수 있다. 앱을 열면 항상 즉시 갱신된다 (R3).
- HealthKit 조회 에러 처리: 데이터 없음·권한 미결정·권한 거부는 0으로 본다. 기기 잠금(`errorDatabaseInaccessible`) 등 그 외 에러는 마지막 스냅샷을 유지한다.
- 위젯이 HealthKit을 직접 읽는 방식은 쓰지 않는다 (CLAUDE.md 핵심 규칙 3 유지).
- 설정 화면에 "실시간이 아님" 안내 문구를 넣는다 (문구는 F01 "설정 화면").
- 시간대 변경/서머타임: 기간 경계는 항상 `ProgressEngine`(F03)이 현재 Calendar 기준으로 재계산한다.

## 데이터
`ProgressSnapshot` → [DATA_MODEL](DATA_MODEL.md) §2. App Group UserDefaults 키 `progressSnapshot`. 권한 요청 여부 `healthAuthRequested`.

## 수용 기준
- [ ] 권한 팝업에 걸음 수 한 항목만 나온다
- [ ] 실기기에서 잠금 해제 상태로 걷고 보통 1시간 이내 스냅샷이 갱신된다 (시스템 상황에 따라 늦어질 수 있음을 감안)
- [ ] 앱을 강제 종료하지 않고 백그라운드로 둔 상태에서 백그라운드 전달로 갱신된다 (실기기)
- [x] 단계가 같으면 reloadAllTimelines가 호출되지 않는다 (AppModelTests)
- [x] 주간 목표에서 `todayValue`가 오늘 걸음 수와 일치한다 (AppModelTests, 실기기 재확인)
- [x] 시뮬레이터에서는 DEBUG 슬라이더로 단계 0~마지막을 직접 확인할 수 있다
- [x] Release 빌드에 DEBUG 슬라이더 코드가 없다 (CI 4단계에서 매번 확인)

## 열린 질문
(없음)

## 변경 이력
- 2026-10-24: 최초 작성
- 2026-10-24: 열린 질문 1차 답변 완료.
- 2026-10-24: 30분 갱신 질문에 시스템 제한 설명 추가 (확정 대기)
- 2026-10-24: 갱신 주기 1시간 확정, 위젯 HealthKit 직접 읽기 안 함. 지표를 걸음 수로 한정(R1 수정, R7 추가). 디버그 슬라이더를 요구사항으로 승격(R8). 주간 시작 일요일, todayValue 추가(F06-R8 대응)
- 2026-10-24: 구현(GOOALL/HealthDataSource.swift, AppModel.swift). 권한 없음 에러를 0으로 처리하는 규칙 추가 (이전 값이 남아 보이는 문제 수정)
- 2026-10-25: 수용 기준 2개 테스트로 확인 (위젯 갱신 함수를 AppModel에 주입해 호출 횟수 검사)
