# 진행 기록

pm 에이전트가 관리. 작업이 끝날 때마다 한 줄씩 추가.
형식: `- [날짜] [에이전트] 무엇을 했는지 — 결과/다음 단계`

## 마일스톤
- [x] M-1. 기획 확정: 스펙 F01~F06 열린 질문 답변, CLAUDE.md 설정값 (`docs/USER_TODO.md` A절)
- [x] M0. 사람 작업: Xcode 프로젝트 생성, 서명, HealthKit·App Group Capability 추가 (`docs/KICKOFF.md` 1단계)
- [x] M1. Shared: 모델, ProgressEngine, 저장소, ThemeRegistry + 단위 테스트
- [x] M2. App: 온보딩(권한→목표→테마), 오늘 화면, HealthKit 읽기·백그라운드 전달
- [x] M3. Widget: Large/Medium/잠금화면, 플레이스홀더로 동작
- [ ] M4. 디자인 이미지 연결 (`/add-theme sixpack`, `/add-theme eyeglow`)
- [ ] M5. 실기기 테스트, `/release-check`, 제출

## 기록
- [2026-10-24] [main] 스펙 F01~F06 열린 질문 정리 완료: 걸음 수 전용, 영어 Gen Z 문구, 주간 일요일 리셋, 갱신 1시간, 선택 테마 5개, 유료 구조 대비, DATA_MODEL.md 신설 — 다음: M1 계획(pm)
- [2026-10-24] [main] Shared/ 폴더를 GOOALL·widgetExtension 타깃에 연결 (pbxproj 1회 예외 수정, 백업 project.pbxproj.bak) — 두 스킴 빌드 성공
- [2026-10-24] [main] M1 완료: Shared/ AppConstants, GoalSettings(+MetricDescriptor), ProgressSnapshot, OnboardingState, Theme, ThemeAccessPolicy, ThemeRegistry, ProgressEngine, SharedStore + 단위 테스트 26건 통과 (UI 변경 없음 → 스크린샷 생략) — 다음: M2 온보딩·오늘 화면·HealthKit
- [2026-10-24] [main] M2 완료(코드): 온보딩 5단계, 오늘 화면, 설정, HealthKit 읽기·1시간 백그라운드 전달, DEBUG 가짜 걸음 수, 텍스트 플레이스홀더(StageImageView) — 시뮬레이터 스크린샷 확인, 테스트 26건 통과. 실기기 수용 기준(F02·F05)은 M5에서 확인 — 다음: M3 위젯
- [2026-10-24] [main] M3 완료(코드): Large/Medium/잠금화면 위젯, 현재+리셋 타임라인(1시간 재요청), 빈 상태, 텍스트 플레이스홀더. 렌더 테스트로 단계 0/5/10 × 3종 확인, 테스트 37건 통과. 실기기 홈 화면·자정 리셋 확인은 M5 — 다음: qa 점검(M1~M3) 또는 M4 디자인 연결
- [2026-10-24] [qa] M1~M3 QA: 빌드 3종 경고 0, 테스트 통과. 🔴1 🟡7 🟢다수
- [2026-10-24] [main] QA 반영: 🔴 설정 화면 주간 목표 덮어쓰기 수정, 🟡 지난 기간 스냅샷 표시/저장, 동시 refresh 경합, 목표 입력 커밋, 위젯 이미지 fullColor, 스펙 체크박스 갱신. AppModel 테스트 추가(테스트 42건 통과). 미처리: 앱 내 개인정보 처리방침 링크(URL 대기)
- [2026-10-24] [main] CI 도입: scripts/ci.sh + GitHub Actions(.github/workflows/ci.yml), 테스트 계획 docs/TEST_PLAN.md — 다음: GitHub 업로드 후 CI 결과 확인
- [2026-10-24] [main] GitHub 업로드(suyoungkwon2/GOOALL) + 첫 CI 성공 (https://github.com/suyoungkwon2/GOOALL/actions/runs/40132003819)
- [2026-10-24] [asset-integrator] eyeglow 1~5단계 시험 등록 — 원본 2929×1106 투명 배경 → 흰 배경·규격 크기 변환본(large/medium), 원본은 Assets/Themes/eyeglow/original/. 0·6~10단계는 플레이스홀더. 오버레이 캡슐 대비 강화
- [2026-10-24] [main] F07 위젯 배경 색: Auto + 파스텔 7색, 선 그림 자동 색(다크 → 흰 선), 온보딩 위젯 미리보기·설정에서 선택, 오늘 화면 동일 적용. eyeglow 이미지 투명 배경으로 재생성. 테스트 62건 통과
- [2026-10-24] [qa] QA 2차(F07·이미지·QA1 수정분): 🔴0 🟡6 🟢9, 공개 저장소 push 가능. 반영: 위젯 안내 화면 스크롤, 목표 입력란 비우기, README 상태, F07-R4 연기 명시, updateAppearance 테스트. 보류: 선 색 기준값(휘도 0.5 → 0.179 검토, 프리셋 추가 전), refresh 경합 테스트
- [2026-10-25] [main] 이미지 외 남은 작업: 설정 About(개인정보 처리방침 링크 PRIVACY.md·버전, F01-R11), String Catalog 누락 문구 추가, 선 색 기준 휘도 0.179, Color(hex:) 격리 경고 제거, AppModel 테스트 5건(위젯 갱신 횟수·주간 todayValue·refresh 경합·온보딩 재개·위젯 일치), CD(TestFlight) 워크플로(.github/workflows/release.yml, Secrets 등록 전 미검증), 17e·Pro Max 레이아웃 확인. 테스트 69건 통과 — 남은 것: 이미지(M4), 실기기·Secrets·App Store Connect(사람), /release-check
- [2026-10-25] [main] PRIVACY.md 사용자 원문에 스타일 적용 + 인앱 구매(테마 1회 구매) 절 추가, F04에 v0.2 유료화 체크(Non-Consumable·구매 복원·라벨). Apple Developer Program 미가입 확인(무료 Personal Team) → 개발 먼저, 출시 직전 가입. F05-R7 위젯 탭 → 오늘 화면(gooall://), 위젯 수치 numericText. 테스트 69건 통과
- [2026-10-25] [qa] QA 3차(출시 전 점검 + 스펙 대조): 🔴1 🟡4 🟢7, CI 통과. 반영: 개인정보 매니페스트 Shared/PrivacyInfo.xcprivacy(UserDefaults 1C8F.1, 앱·위젯 번들) + CI 확인 단계, 빌드 번호 UTC 시각 통일, 워크플로 permissions, reloadWidgets @MainActor, PRIVACY.md 구매 복원 조건문. 사용자 결정 대기: iPad 지원 여부. 남은 것: 이미지(M4)·사람 작업(M5)
