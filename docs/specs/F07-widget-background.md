# F07. 위젯 배경 색

- 상태: Ready
- 담당: ios-dev, widget-dev
- 관련 스펙: F01(온보딩), F04(테마 이미지), F05(위젯), F06(오늘 화면), [DATA_MODEL](DATA_MODEL.md)
- 마지막 수정: 2026-10-25

## 목적
사용자가 위젯 배경 색을 골라 자기 홈 화면에 어울리게 만든다. 기본값은 기기의 라이트/다크 설정을 따르고, 그림(선)은 배경에 맞춰 잘 보이는 색으로 자동으로 바뀐다.

## 요구사항
| ID | 요구사항 | 우선순위 |
|---|---|---|
| F07-R1 | 위젯 배경 색 선택: "Auto"(System, 기본) + 파스텔 프리셋 7색 (아래 목록). 자유 색상 선택기는 없음 | Must |
| F07-R2 | "System" = 라이트 모드 흰색, 다크 모드 어두운 색(예: `#1C1C1E`). 기기 설정이 바뀌면 자동으로 따라간다 | Must |
| F07-R3 | 선 그림 테마(`artStyle = lineArt`)는 투명 배경 이미지를 단색으로 칠해서 그린다. 선 색은 배경 밝기에 따라 자동 (밝은 배경 → 검정, 어두운 배경 → 흰색) | Must |
| F07-R4 | 컬러 그림 테마(`artStyle = fullColor`)는 이미지를 그대로 그린다. 다크 전용 이미지(`_dark`) 조회는 첫 fullColor 테마를 추가할 때 구현한다 (현재 해당 테마 없음) | Should |
| F07-R5 | 온보딩 위젯 안내 화면(F01 5단계)에서 실제 위젯 미리보기를 보며 고르고, 설정 화면에서 언제든 바꿀 수 있다. 바꾸면 위젯에 즉시 반영 (5초 이내) | Must |
| F07-R6 | 고른 배경 색은 앱 오늘 화면의 그림 카드와 온보딩 미리보기에도 똑같이 적용한다 (위젯과 같은 모습) | Must |

## 동작 상세
- 홈 화면을 투명/틴트 모드로 쓰는 사용자는 iOS가 위젯 배경을 직접 바꾸므로, 고른 색 대신 시스템 표현이 나온다 (앱이 강제할 수 없음).
- 수치 오버레이 캡슐(F05)은 배경 색과 상관없이 지금처럼 진한 반투명 캡슐 + 흰 글자.
- 이미지가 없는 단계의 플레이스홀더도 고른 배경 색 + 자동 선 색으로 표시한다.
- 테마의 `artStyle`은 ThemeRegistry(F04)에 데이터로 둔다. eyeglow = lineArt, sixpack = 디자인 나오면 결정 (기본 lineArt).

## 배경 색 목록
| id | 이름 (UI) | 색 | 선 색 |
|---|---|---|---|
| `system` | Auto | 라이트 `#FFFFFF` / 다크 `#1C1C1E` | 검정 / 흰색 |
| `milk` | Milk | `#FBF8F3` | 검정 |
| `cream` | Cream | `#FFF1CC` | 검정 |
| `pink` | Pink | `#FFD6E2` | 검정 |
| `sky` | Sky | `#D3E8FF` | 검정 |
| `mint` | Mint | `#CFF3E2` | 검정 |
| `lavender` | Lavender | `#E5DBFF` | 검정 |
| `midnight` | Midnight | `#33384F` | 흰색 |

- 선 색은 목록에 고정하지 않고 배경 밝기로 계산한다: 상대 휘도 0.179 미만이면 흰 선 (검정·흰색 중 WCAG 대비가 큰 쪽). 색을 추가해도 코드 분기가 늘지 않는다.

## 문구 (영어, F01 톤)
- 온보딩 위젯 안내 화면 색 선택 라벨: Pick a color that vibes with your home screen 🎨
- 설정 섹션 이름: Widget / 항목: Background

## 데이터
`WidgetAppearance { backgroundID }` → App Group 키 `widgetAppearance` (DATA_MODEL §6). 테마 `artStyle` (DATA_MODEL §4).

## 수용 기준
- [x] 기본값(System)에서 라이트 모드는 흰 배경 + 검은 선, 다크 모드는 어두운 배경 + 흰 선으로 보인다 (Large 렌더 확인)
- [x] 프리셋 색마다 선 색이 대비가 충분한 쪽(검정/흰색)으로 자동 선택된다
- [ ] 설정에서 배경 색을 바꾸면 5초 안에 위젯에 반영된다
- [x] 저장된 값이 없거나 깨져 있으면 System으로 동작한다

## 열린 질문
(없음)

## 변경 이력
- 2026-10-24: 최초 작성 (사용자 제안: 온보딩에서 위젯 배경 색 선택, 다크모드는 흰 선)
- 2026-10-24: 열린 질문 답변 — Auto + 파스텔 7색, 온보딩 위젯 안내 화면에서 선택, 오늘 화면에도 적용 → Ready
- 2026-10-24: 구현 (Shared/WidgetAppearance.swift, StageImageView, GOOALL/BackgroundPicker.swift, widget containerBackground). 수용 기준 3개 테스트로 확인, 설정→위젯 5초 반영은 실기기 확인 필요
- 2026-10-24: QA 2차 반영 — R4의 `_dark` 조회는 fullColor 테마 추가 시로 연기 명시
- 2026-10-25: 선 색 기준 휘도 0.5 → 0.179 (대비가 큰 쪽 선택, QA2 보류 항목). 현재 8색 결과는 같음. 문구를 String Catalog에 추가
