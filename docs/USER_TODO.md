# 사용자(나)가 해야 하는 일

에이전트가 대신할 수 없는 것만 모았다. 위에서부터 순서대로.

## A. 기획 확정 (Claude Code 시작 전, 사람 작업)
- [V] 각 스펙(F01~F06)의 **"열린 질문"**에 답 적기 → 상태를 Draft → Ready로
  - F01: 앱 이름 후보, 소개 문구, 운동 시간 지표를 MVP에 넣을지
  - F02: 디버그용 가짜 걸음 수 슬라이더 넣을지(추천: 넣기)
  - F04: 테마 표시명, 0단계 응원 문구, 유료 모델 여부
  - F05: 잠금화면은 텍스트+게이지로 확정? 오버레이 정보 우선순위
- [V] `CLAUDE.md`의 **프로젝트 설정값** 채우기 (앱 이름, 번들 ID, App Group ID, 최소 iOS 버전)
- [V] 앱 이름 후보가 상표/앱스토어에서 겹치지 않는지 검색: 안겹침
- [V] 한국어만 지원할지, 영어도 할지 결정 (스펙 F01에 반영): 영어만 우선 지원, 한국어 및 다국어는 추후 지원

## B. 계정·환경 (사람만 가능)
- [V] Apple Developer Program 가입 (연회비 발생, 승인에 1~2일 걸릴 수 있으니 **가장 먼저**)
- [V] Xcode 26.3 이상 설치
- [V] Claude Code에 XcodeBuildMCP 추가 (`docs/KICKOFF.md` 0단계)
- [ ] 개인정보 처리방침 확인: 저장소 루트 `PRIVACY.md` 초안을 읽고 OK/수정 (앱 설정 화면 링크와 App Store Connect의 Privacy Policy URL에 `https://github.com/suyoungkwon2/GOOALL/blob/main/PRIVACY.md` 사용. 연락처는 GitHub Issues로 해 둠 — 이메일을 넣고 싶으면 알려주기)

## C. Xcode 설정 (GOOALL 프로젝트는 대부분 완료됨)
완료 확인됨: 프로젝트·위젯 타깃 생성, 서명 Team, HealthKit(+Background Delivery), App Groups(`group.com.mel.GOOALL`, 앱·위젯 양쪽)
- [V] **건강 권한 문구 추가**: 앱 타깃 → Info 탭 → `+` → "Privacy - Health Share Usage Description"(`NSHealthShareUsageDescription`). 없으면 권한 요청 시 크래시
- [V] Info 탭의 **빈 `Document types` 항목 삭제** (키 추가하다 생긴 것으로 보임. 앱스토어 검증 오류 가능)
- [V] **Shared 폴더를 두 타깃에 추가**: 저장소 루트에 `Shared/` 폴더가 있으면 (없으면 Finder에서 새로 만들기) Xcode 프로젝트 탐색기에서 프로젝트 이름 우클릭 → "Add Files to GOOALL…" → `Shared` 선택 → Add to targets에 **GOOALL과 widgetExtension 둘 다 체크**. 추가 후 파일을 선택해 오른쪽 File Inspector의 Target Membership에 둘 다 체크되는지 확인
- [V] 최소 iOS(현재 26.5)를 낮출지 결정: 타깃 → General → Minimum Deployments: 26.0으로 하향 결정
- [V] ⌘R로 빈 앱이 시뮬레이터에서 뜨는지 확인

## D. 디자인 (내가 직접)
- [V] 우선순위: **sixpack 0단계와 마지막 단계 먼저** (나머지 단계는 나중에 채워도 됨 — 플레이스홀더로 개발 진행 가능): 플레이스 홀더로 진행 (텍스트로 식스팩 1 2 3 4 등으로 단계 표시)
- [ ] `docs/DESIGN_HANDOFF.md` 규격대로 PNG 제작 → `Assets/Themes/<id>/`에 저장 → `/add-theme <id>`
- [ ] 두 테마(sixpack, eyeglow) 전 단계 완성
- [ ] (선택) hair, skinfirm, darkcircle, elevenabs, brighteyes — 준비되는 대로 `/add-theme`
- [ ] 앱 아이콘 1024×1024
- [ ] 온보딩 일러스트, 위젯 추가 안내 이미지(F01-R7)

## E. 개발 중 확인
- [ ] 마일스톤마다 Claude가 보내는 **스크린샷 확인**하고 OK/수정 피드백
- [ ] 스펙에서 코드와 어긋났다고 보고되면 어느 쪽이 맞는지 결정
- [ ] 실기기(아이폰)로 빌드해서 실제로 걸어보기 — 시뮬레이터엔 실제 걸음 데이터가 없음
- [ ] 애플워치가 있다면 워치 데이터가 반영되는지 확인
- [ ] 자정을 넘겨서 리셋되는지 하루 사용 테스트

## F. 출시 (사람만 가능)
- [ ] (CD 준비, docs/TEST_PLAN.md 7절) App Store Connect → Users and Access → Integrations → App Store Connect API에서 **Admin** 역할 키 발급(.p8는 한 번만 다운로드됨) → GitHub 저장소 Settings → Secrets and variables → Actions에 `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`(.p8 내용 전체) 등록. 인증서 파일은 필요 없음
- [ ] App Store Connect에 앱 등록 후 `git tag v0.1.0 && git push origin v0.1.0` → Actions에서 TestFlight 업로드 확인
- [ ] `/release-check` 실행하고 "사용자 확인 필요" 항목 처리
- [ ] App Store Connect에 앱 등록, 개인정보 라벨 작성(건강 데이터 처리 방식)
- [ ] 스크린샷 촬영 (실기기 홈 화면에 위젯 놓은 모습이 가장 효과적)
- [ ] 앱 설명문·키워드 작성
- [ ] TestFlight로 지인 3~5명에게 테스트
- [ ] 심사 제출 → 거절 시 사유 확인하고 Claude에게 전달
- [ ] 출시 후 마케팅: 위젯 변화 전/후 화면녹화 숏폼 (이 앱의 가장 강한 홍보 수단)
