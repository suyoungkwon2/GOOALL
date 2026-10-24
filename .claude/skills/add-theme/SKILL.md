---
name: add-theme
description: 새 모티베이션 테마 이미지 세트를 검증하고 앱·위젯에 등록한다. 사용자가 "/add-theme <themeID>" 하거나 "새 테마 넣었어", "이미지 추가했어"라고 할 때 사용.
---

# 테마 추가 절차

인자: themeID (없으면 Assets/Themes/ 아래 아직 등록 안 된 폴더를 찾아 사용자에게 확인)

## 1. 검증 (docs/DESIGN_HANDOFF.md 기준)
`Assets/Themes/<themeID>/` 의 파일을 나열하고 확인:
- 이름 규칙 `<themeID>_<size>_<NN>(_dark)?.png`
- large 단계 번호가 00부터 연속인지, medium이 있다면 large와 단계 수가 같은지
- 해상도: `sips -g pixelWidth -g pixelHeight <file>` 로 규격과 비교 (±2px 허용)
- 색 공간 sRGB, 파일 크기 개당 1MB 이하 권장 (위젯 메모리)
- theme.json이 있으면 JSON 유효성과 stageCount 일치 여부

문제가 있으면 여기서 멈추고 표로 보고한다.

## 2. Asset Catalog 등록
- 앱과 위젯 익스텐션이 모두 접근하는 Shared 에셋 카탈로그에 `Themes/<themeID>/` 폴더(namespace 체크) 생성
- 각 이미지마다 `.imageset` 폴더 + `Contents.json` (3x 단일 이미지, `_dark`가 있으면 appearances luminosity dark 항목 추가)

## 3. ThemeRegistry 등록
`Shared/ThemeRegistry.swift`의 테마 배열에 항목 추가 (theme.json 값, 없으면 기본값). switch/if 추가 금지.

## 4. 확인
- 빌드
- `#Preview(as: .systemLarge)`로 단계 0, 중간, 마지막 스크린샷
- 사용자에게 스크린샷 3장 + 등록 요약을 보여주고 디자인 확인 요청

## 5. 기록
docs/PROGRESS.md에 `- [날짜] [asset-integrator] <themeID> 테마 등록 (N단계)` 추가
