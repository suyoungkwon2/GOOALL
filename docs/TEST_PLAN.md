# 테스트 계획 (CI/CD 포함)

무엇을, 언제, 어떻게 검증하는지의 원본. 기능별 "무엇이 맞는 동작인가"는 `docs/specs/`가 원본이고, 이 문서는 그 수용 기준을 어떤 방법으로 확인하는지를 정한다.

## 1. 테스트 단계 한눈에 보기
| 단계 | 언제 | 누가 | 무엇을 | 자동? |
|---|---|---|---|---|
| 단위·렌더 테스트 | 코드 변경마다 (로컬 + CI) | 에이전트 / GitHub Actions | 진행률 계산, 모델, 저장소, 앱 상태 흐름, 위젯 타임라인, 위젯 화면 렌더 | ✅ |
| CI | main push·모든 PR | GitHub Actions | 위젯 빌드 → 테스트 → Release 빌드 → DEBUG 코드 누출 검사 | ✅ |
| 시뮬레이터 화면 확인 | 화면을 바꾼 작업 끝 | 에이전트 | 스크린샷 (DEBUG 런치 인자로 화면 이동) | 반자동 |
| 마일스톤 QA | 마일스톤 끝 | qa 에이전트 | 스펙↔코드 대조(`/update-spec` C절), 규칙 위반, 심사 리스크 | 수동 실행 |
| 실기기 테스트 | M5, 큰 변경 후 | 사용자 | 실제 걸음, 백그라운드 갱신, 자정 리셋, 위젯 | ❌ (사람) |
| 출시 전 점검 | 제출 전 | qa + 사용자 | `/release-check` | 반자동 |
| CD (TestFlight 배포) | `v*` 태그 push (7절) | GitHub Actions | CI 검사 → 서명 아카이브 → TestFlight 업로드 | ✅ (Secrets 등록 후) |

## 2. CI (자동)
- 설정: `.github/workflows/ci.yml` → `scripts/ci.sh` 실행. **로컬에서도 `scripts/ci.sh` 한 줄로 같은 검사**를 돌릴 수 있다.
- 트리거: `main` 브랜치 push, 모든 Pull Request, 수동 실행(Actions 탭 → CI → Run workflow).
- 러너: GitHub `macos-26`, 설치된 최신 Xcode 26.x. 서명 없이(`CODE_SIGNING_ALLOWED=NO`) 시뮬레이터에서 빌드·테스트.
- 순서 (하나라도 실패하면 CI 실패):
  1. 위젯 익스텐션 빌드
  2. `GOOALLTests` 전체 (iOS 26+ iPhone 시뮬레이터)
  3. Release 구성 빌드
  4. Release 바이너리에 DEBUG 전용 문자열(`debugMockSteps`, `-debugOnboardingStep`, `Use fake steps`)이 없는지 (F02-R8)
- 결과물: Actions 실행 페이지의 **ci-results** 아티팩트 = 테스트 결과(`TestResults.xcresult`) + 위젯 렌더 PNG(`widget-snapshots/`, 단계 0/5/10 × Large/Medium/잠금화면). 14일 보관.
- CI가 실패하면: main에 머지하지 않는다. 에이전트는 다음 작업 전에 원인을 고치고, 고칠 수 없으면 사용자에게 보고한다.

## 3. 자동 테스트 목록 (`GOOALLTests/`)
| 파일 | 대상 | 확인하는 스펙 |
|---|---|---|
| `ProgressEngineTests.swift` | 진행률·단계·기간·일평균·스냅샷 | F03 수용 기준 전부 (경계값, 자정, 일요일 리셋, 로케일 무관, 서머타임, 비정상 입력) |
| `SharedModelTests.swift` | 목표 기본값·범위 보정, ThemeRegistry, SharedStore, 위젯 배경 색·선 색 | F01-R5/R8, F04-R2/R7, F07, DATA_MODEL §5·6 |
| `AppModelTests.swift` | 갱신·설정 변경 흐름 (가짜 HealthDataSource·위젯 갱신 주입) | F01-R6, 온보딩 재개, F02-R2/R5 (단계 같으면 위젯 갱신 안 함), 주간 todayValue, refresh 경합, F06 (지난 기간 0, 위젯과 같은 엔트리) |
| `WidgetTimelineTests.swift` | 위젯 타임라인 + 위젯 화면 렌더 (배경 8종 × 라이트/다크 포함) | F05-R5/R8, F05 수용 기준 1·2·3, F07 |

규칙:
- 동작이 바뀌는 코드에는 같은 작업에서 테스트를 추가하거나 고친다 (스펙 갱신과 함께).
- 날짜가 걸린 로직은 `Date`/`Calendar`를 주입해 테스트한다 (F03-R5). 시간대는 `America/New_York`(서머타임 있음)으로 고정.
- HealthKit·WidgetKit은 테스트에서 직접 쓰지 않는다. `HealthDataSource` 가짜 구현을 주입한다.
- 렌더 테스트 PNG는 환경변수 `SNAPSHOT_DIR`(xcodebuild에서는 `TEST_RUNNER_SNAPSHOT_DIR`)이 있을 때만 저장한다. 픽셀 비교는 하지 않는다 (디자인 이미지가 들어오면 사람이 확인).

## 4. 시뮬레이터 화면 확인 (DEBUG 빌드 전용 런치 인자)
```
xcrun simctl launch <SIM_ID> com.mel.GOOALL -debugOnboardingStep intro|theme|goal|health|widgetGuide
xcrun simctl launch <SIM_ID> com.mel.GOOALL -debugSkipOnboarding -debugMockSteps 6240 [-debugPeriod weekly] [-debugTheme eyeglow] [-debugBackground pink]
xcrun simctl io <SIM_ID> screenshot shot.png
```
- 확인 기기: 기본 iPhone 17, 레이아웃 변경 시 가장 작은 기기(iPhone 17e)와 가장 큰 기기(Pro Max)도.
- 라이트/다크: `xcrun simctl ui <SIM_ID> appearance dark`

## 5. 마일스톤 QA (qa 에이전트)
`.claude/agents/qa.md` 기준. 결과는 🔴 차단 / 🟡 수정 권장 / 🟢 참고 표로 받고, 🔴는 다음 마일스톤 전에 반드시 고친다.

## 6. 실기기 테스트 체크리스트 (사람)
설치: Xcode에서 iPhone 선택 후 ⌘R. 처음 한 번은 iPhone **설정 → 일반 → VPN 및 기기 관리**에서 개발자 앱 신뢰.
- [ ] 온보딩 끝까지, 건강 권한 팝업에 걸음 수 한 항목만 (F02)
- [ ] 오늘 화면 걸음 수가 건강 앱과 같다
- [ ] 목표 숫자 입력 후 키보드를 닫지 않고 Next → 입력값 반영·범위 보정 (F01)
- [ ] 홈 화면에 Large/Medium, 잠금화면에 직사각형 위젯 추가 → 앱과 같은 단계 (F05, F06)
- [ ] 설정에서 테마·배경 색 변경 → 5초 안에 위젯 반영 (F01-R6, F07-R5)
- [ ] 앱을 강제 종료하지 않고 걷기 → 보통 1시간 안에 위젯 단계 변경 (F02, F05)
- [ ] 자정 지나서 앱을 열지 않아도 위젯 0 상태 (F05), 앱을 켜 둔 채 자정 → 앱도 0 (F06)
- [ ] 틴트/클리어 홈 화면 모드에서 위젯이 읽힌다
- [ ] (워치가 있으면) 워치 걸음이 중복 없이 반영 (F02-R6)
- [ ] 앱 삭제 후 재설치 → 온보딩 다시 (F01)
- [ ] Settings의 "Use fake steps"는 꺼 둘 것 (DEBUG 빌드에만 있음)

## 7. CD (TestFlight 배포)
- 설정: `.github/workflows/release.yml` → `scripts/ci.sh`(2절 검사 전부) → `scripts/release.sh`(아카이브·업로드). 내보내기 설정은 `scripts/ExportOptions.plist`.
- 트리거: `v*` 태그 push. 예: `git tag v0.1.0 && git push origin v0.1.0` → 버전 0.1.0, 빌드 번호 = Actions 실행 번호(자동 증가). Actions 탭에서 수동 실행도 가능(버전은 프로젝트 값 유지).
- 서명: Xcode 자동 서명 + App Store Connect API 키(`-allowProvisioningUpdates`). 배포 인증서는 Apple 클라우드 관리 인증서를 쓰므로 인증서·프로비저닝 파일을 Secrets에 넣지 않는다.
- 필요한 Secrets (사용자, USER_TODO F절): `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`(.p8 파일 내용 전체). API 키 역할은 **Admin** (클라우드 관리 배포 인증서 사용 권한 때문). 없으면 워크플로가 안내 메시지와 함께 실패한다. **비밀 값은 절대 저장소에 커밋하지 않는다.**
- 전제: App Store Connect에 앱(`com.mel.GOOALL`)이 등록되어 있어야 업로드된다.
- 상태: Secrets 등록 전이라 실제 업로드는 아직 검증 전. 첫 태그 push 결과를 보고 고친다.
- TestFlight 외부 테스터 배포와 심사 제출은 사람이 App Store Connect에서 직접 한다.

## 변경 이력
- 2026-10-24: 최초 작성 (CI 도입, QA 1차 결과 반영)
- 2026-10-24: F07(위젯 배경 색) 테스트·체크리스트 추가
- 2026-10-25: CD(TestFlight) 워크플로 추가, AppModel 테스트(위젯 갱신 횟수·주간 todayValue·경합·온보딩 재개·위젯 일치) 추가
