# 기능 스펙 인덱스

기능마다 스펙 파일 1개. **이 폴더가 "무엇을 만들지"의 유일한 원본(source of truth)이다.**
코드와 스펙이 다르면 스펙을 고치거나 코드를 고친다 — 둘을 다르게 두지 않는다.

| ID | 기능 | 파일 | 상태 | 담당 에이전트 |
|---|---|---|---|---|
| F01 | 온보딩·목표 설정 | [F01-onboarding-goal.md](F01-onboarding-goal.md) | Ready | ios-dev |
| F02 | 건강 데이터 수집 | [F02-health-data.md](F02-health-data.md) | Ready | ios-dev |
| F03 | 진행률 엔진 | [F03-progress-engine.md](F03-progress-engine.md) | Built | ios-dev |
| F04 | 테마 시스템 | [F04-themes.md](F04-themes.md) | Ready | asset-integrator, ios-dev |
| F05 | 위젯 | [F05-widgets.md](F05-widgets.md) | Ready | widget-dev |
| F06 | 오늘 화면 | [F06-today-screen.md](F06-today-screen.md) | Ready | ios-dev |
| F07 | 위젯 배경 색 | [F07-widget-background.md](F07-widget-background.md) | Draft | ios-dev, widget-dev |
| — | 공용 데이터 모델 | [DATA_MODEL.md](DATA_MODEL.md) | Ready | ios-dev, widget-dev |

## 상태 값
- **Draft**: 사용자가 아직 내용을 확정하지 않음. 에이전트는 구현 전에 열린 질문을 사용자에게 확인한다.
- **Ready**: 사용자가 확정. 구현 가능.
- **Built**: 구현 완료, 수용 기준 통과.
- **Changed**: 구현 후 스펙이 바뀜 → 코드 수정 필요.

## 규칙
1. 새 기능은 `_TEMPLATE.md`를 복사해 `Fxx-이름.md`로 만들고 이 표에 추가한다.
2. 동작이 바뀌는 코드 변경 = 같은 작업에서 스펙도 수정 + 맨 아래 변경 이력에 한 줄 (`/update-spec` 스킬).
3. 스펙의 "열린 질문"이 남아 있으면 상태를 Ready로 올리지 않는다.
4. 요구사항 번호(F03-R2 등)는 재사용하지 않는다. 삭제할 땐 취소선 처리.
