# 디자인 핸드오프 규격

디자이너(사용자)는 이 규격대로 이미지를 `Assets/Themes/<themeID>/`에 넣기만 하면 된다. 나머지는 `/add-theme` 스킬이 처리한다.

## 파일 이름 규칙
```
<themeID>_<size>_<stage 2자리>.png
예: sixpack_large_00.png ... sixpack_large_10.png
```
- themeID: 영문 소문자, 공백 없음 (`sixpack`, `eyeglow`, `hair` …)
- size: `large`, `medium`, `lock`
- stage: `00`부터 시작, 연속 번호. 기본 11장(00~10)

## 해상도 (@3x 기준, PNG, sRGB)
| size | 용도 | 권장 픽셀 | 비고 |
|---|---|---|---|
| large | 홈 화면 Large 위젯 | 1092 × 1146 | 모서리 둥글게 잘림 → 가장자리 40px 안쪽에 핵심 요소 |
| medium | 홈 화면 Medium 위젯 | 1092 × 510 | 가로형. large를 크롭하지 말고 별도 구도 권장 |
| lock | 잠금화면 직사각형 | 선택 사항 | 시스템이 단색 처리. 없으면 텍스트+진행률 바로 대체 |

기기마다 위젯 크기가 조금씩 달라서, 이미지는 `scaledToFill`로 꽉 채운다. 잘려도 되는 여백을 두세요.

- **그림 종류 (F07)**
  - **선 그림(lineArt, 기본)**: **투명 배경 + 한 가지 색 선**으로 그려 주세요 (선 색은 상관없음, 투명도만 사용). 앱이 사용자가 고른 위젯 배경 색 위에 선을 검정/흰색으로 자동으로 칠합니다. 다크 전용 이미지가 필요 없습니다.
  - **컬러 그림(fullColor)**: 배경까지 채운 완성 그림. 테마를 이 방식으로 바꾸려면 ThemeRegistry의 artStyle을 바꾼다.
- **size별 비율을 지켜 주세요.** 가로로 긴 그림(예: 2929×1106)을 large에 넣으면 가운데만 잘려 보입니다. 비율이 다른 원본을 받으면 asset-integrator가 잘림 없이 규격 크기에 맞춘 변환본(투명 배경 유지)을 만들고 원본은 `Assets/Themes/<id>/original/`에 보관합니다.

## 다크모드
- 기본은 이미지 1세트로 라이트/다크 공용.
- 다크 전용이 필요하면 `<themeID>_<size>_<stage>_dark.png` 추가 (없으면 공용 사용).

## 텍스트 오버레이 영역
위젯 위에 코드로 숫자(예: "6,240 / 10,000")를 얹는다. **하단 20% 영역**은 복잡한 디테일을 피하거나, 오버레이가 필요 없도록 `theme.json`에서 끌 수 있다.

## theme.json (테마 폴더마다 1개, 선택)
```json
{
  "id": "sixpack",
  "displayName": "Six-Pack",
  "tagline": "Belly era → Six-pack era",
  "stageCount": 11,
  "overlay": "bottom",          // bottom | top | none
  "overlayTextColor": "#FFFFFF",
  "startMessage": "Your six-pack's waiting. Let's get walking 🚶‍♀️",
  "doneMessage": "Six-pack: unlocked. You ate that 🔥"
}
```
없으면 기본값: stageCount = 파일 개수, overlay = bottom, 흰색 텍스트, 문구는 docs/specs/F04-themes.md 테마 목록. 필드 정의는 docs/specs/DATA_MODEL.md §4.

## 단계 연출 팁
- 0단계(시작)도 귀엽게. 매일 아침 보는 그림이다.
- 변화는 초반에 크게 보이도록 (1~3단계에서 차이가 확 느껴지면 첫 걸음 동기가 커진다).
- 마지막 단계는 "보상" 느낌으로 확실히 다르게.

## MVP 테마
기본 (먼저 제작):
| themeID | 0단계 | 10단계 |
|---|---|---|
| sixpack | 뱃살 가득 | 선명한 식스팩 |
| eyeglow | 퀭한 눈 | 맑고 반짝이는 눈 |

선택 (준비되는 대로 `/add-theme`. 등록 전에는 앱에 안 보임):
| themeID | 0단계 | 10단계 |
|---|---|---|
| hair | 부스스한 머리 | 윤기 나는 머릿결 |
| skinfirm | 처진 피부 | 탱탱한 피부 |
| darkcircle | 짙은 다크서클 | 다크서클 없는 얼굴 |
| elevenabs | 말랑한 배 | 11자 복근 |
| brighteyes | 충혈되고 피곤한 눈 | 맑고 하얀 눈 |
