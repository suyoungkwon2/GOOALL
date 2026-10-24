# F04. 테마 시스템

- 상태: Ready
- 담당: asset-integrator, ios-dev
- 관련 스펙: F01(선택), F03(stageCount), F05·F06(렌더링), docs/DESIGN_HANDOFF.md(파일 규격), [DATA_MODEL](DATA_MODEL.md)
- 마지막 수정: 2026-10-24

## 목적
모티베이션 테마를 코드 수정 없이 "이미지 폴더 + 메타데이터"로 추가할 수 있게 한다.

## 요구사항
| ID | 요구사항 | 우선순위 |
|---|---|---|
| F04-R1 | 테마 = id, 표시 이름, 한 줄 소개(tagline), 단계 수, 오버레이 위치/색, 0단계 응원 문구, 완료 문구, 접근 권한(access), 이미지 세트 (DATA_MODEL §4) | Must |
| F04-R2 | `ThemeRegistry`가 앱·위젯 양쪽에서 같은 목록을 제공 | Must |
| F04-R3 | 이미지가 없는 단계/테마는 `PlaceholderStageView`로 대체 | Must |
| F04-R4 | MVP 기본 테마 2개: `sixpack`, `eyeglow`. 이미지가 없어도 플레이스홀더로 처음부터 등록 | Must |
| F04-R5 | 테마 추가는 `/add-theme` 스킬 한 번으로 끝난다 | Must |
| F04-R6 | 테마별 문구 톤(0단계 응원 문구, 완료 문구) 지정 (아래 테마 목록) | Must |
| F04-R7 | 유료 테마 대비 구조: `Theme.access`(`.free` / `.paid(productID:)`)와 잠금 판단 단일 지점 `ThemeAccessPolicy.isUnlocked(_:)`. **MVP는 모든 테마 `.free`, 정책은 항상 true를 반환**하며 StoreKit 코드·잠금 UI·가격 표시는 만들지 않는다. 테마 목록을 보여주는 곳은 모두 이 정책을 거친다 | Must |
| F04-R8 | MVP 선택 테마 5개 (아래 목록). 디자인 이미지가 준비되면 `/add-theme`로 등록하고, 등록 전에는 앱에 노출하지 않는다 | Could |

## 테마 목록
문구 톤은 F01과 같다 (친구/언니 말투, 건강 효과 주장 금지 — 모습을 "보여주는" 표현만).

### 기본 (F04-R4)
| id | displayName | tagline | startMessage (0단계) | doneMessage (100%) |
|---|---|---|---|---|
| `sixpack` | Six-Pack | Belly era → Six-pack era | Your six-pack's waiting. Let's get walking 🚶‍♀️ | Six-pack: unlocked. You ate that 🔥 |
| `eyeglow` | Eye Glow | Zombie eyes → Sparkly eyes | Sleepy eyes? Same. Let's wake them up 👀 | Eyes sparkling. Main character energy ✨ |

### 선택 (F04-R8 — 이미지 준비되면 등록)
| id | displayName | tagline | startMessage (0단계) | doneMessage (100%) |
|---|---|---|---|---|
| `hair` | Glossy Hair | Frizz era → Shampoo-ad hair | Bad hair day? Let's walk it off 💇‍♀️ | Hair-flip worthy. Period 💁‍♀️ |
| `skinfirm` | Bouncy Skin | Meh skin → Bouncy glass skin | Let's get that bounce going 🫧 | Glass skin, achieved. Glowing fr ✨ |
| `darkcircle` | Bye Dark Circles | Panda eyes → Fresh face | Panda mode: on. Not for long 🐼 | Dark circles? Never heard of her 💅 |
| `elevenabs` | 11-Line Abs | Soft tummy → 11-line abs | Two little lines. That's all we need ✌️ | 11-line abs, served 🔥 |
| `brighteyes` | Bright Eyes | Tired eyes → Crystal-clear eyes | Eyes looking tired? Let's brighten up 👁️ | Crystal clear. Iconic 💎 |

## 동작 상세
- 파일 규격·해상도·이름 규칙은 docs/DESIGN_HANDOFF.md가 원본. 이 스펙에는 복사하지 않는다.
- 테마 변경 시 진행 값은 유지, 단계 수가 다르면 progress 비율로 재계산한다.
- 저장된 테마가 레지스트리에 없거나 `isUnlocked == false`이면 `sixpack`으로 대체한다 (v0.2 환불·제거 대비).
- v0.2 유료화(1회 구매로 테마 구매) 때 할 일: StoreKit 2 상품 등록, 해당 테마를 `.paid(productID:)`로 변경, `ThemeAccessPolicy`를 `Transaction.currentEntitlements` 기반으로 교체, 테마 선택 화면에 잠금/구매 UI 추가. 위젯은 정책 결과만 따른다.

## 콘텐츠 가이드라인 (심사 대응)
- 노골적 성적 표현 금지. 신체 테마는 "만화/일러스트풍 또는 상징적 표현" 우선.
- 건강 효과를 주장하는 문구 금지.
- 성기·엉덩이 등 성적으로 읽힐 수 있는 신체 테마는 만들지 않는다 (가이드라인 1.1.4).

## 수용 기준
- [ ] 새 테마 폴더를 넣고 `/add-theme`만 실행했을 때 소스 코드 변경은 ThemeRegistry 항목 추가뿐이다
- [x] 이미지 일부가 누락돼도 앱·위젯이 크래시하지 않는다 (현재 전부 플레이스홀더)
- [ ] 기본 테마 2개 모두 단계 0과 마지막 단계에서 위젯 Large 스크린샷이 의도대로 보인다
- [x] 코드에서 테마 잠금 여부를 판단하는 곳이 `ThemeAccessPolicy` 한 곳뿐이다
- [x] MVP 빌드에 StoreKit import가 없다

## 열린 질문
(없음)

## 변경 이력
- 2026-10-24: 최초 작성
- 2026-10-24: 열린 질문 1차 답변 완료.
- 2026-10-24: 표시명·문구를 영어로 확정, 0단계 응원 문구 작성(R6 Must로). 선택 테마 5개 추가(R8, 탱탱한 엉덩이는 제외). 유료 1회 구매는 v0.2로 미루고 구조만 대비(R7)
- 2026-10-24: eyeglow 1~5단계 시험 이미지 등록(Shared/Themes.xcassets). 수치 오버레이 캡슐을 진하게(밝은 이미지에서도 읽히도록)
- 2026-10-24: Theme.artStyle 추가(sixpack·eyeglow = lineArt). eyeglow 이미지를 투명 배경으로 재생성
