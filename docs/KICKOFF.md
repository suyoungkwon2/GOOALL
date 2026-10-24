# 킥오프 가이드 — 이 폴더로 시작하는 법

## 0. 준비 (한 번만)
- Xcode 26.3 이상, Apple Developer 계정
- Claude Code 설치된 상태에서 XcodeBuildMCP 추가:
  ```
  claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp
  ```

## 1. 사람이 하는 Xcode 설정
> GOOALL 프로젝트는 이 단계의 대부분이 이미 끝났다. 남은 항목은 `docs/USER_TODO.md` C절을 따른다.
 (약 15분)
1. Xcode → New Project → iOS App, SwiftUI, 이름 정하기. 이 키트 폴더를 프로젝트 루트로 지정 (CLAUDE.md, .claude/, docs/가 같은 위치에 있도록)
2. File → New → Target → **Widget Extension** (Include Live Activity 체크 해제)
3. 앱 타깃 Signing & Capabilities:
   - Team 선택
   - **+ HealthKit** (Background Delivery 체크)
   - **+ App Groups** → `group.<번들ID>` 추가
4. 위젯 타깃에도 같은 **App Groups** 추가
5. ⌘R 한 번 실행해서 빈 앱이 시뮬레이터에 뜨는지 확인

## 1.5 기획 확정
`docs/USER_TODO.md` A절 — 스펙의 "열린 질문"에 답하고, CLAUDE.md의 프로젝트 설정값을 채운다.

## 2. Claude Code에 던질 첫 프롬프트
프로젝트 폴더에서 `claude` 실행 후:

```
CLAUDE.md와 docs/specs/를 읽고, Draft인 스펙에 남은 열린 질문이 있으면 먼저 나에게 물어봐. 다 해결되면 pm 에이전트로 M1~M3 작업 계획을 세워줘.
계획을 보여주고 내가 OK하면, 작업마다 담당 에이전트(ios-dev, widget-dev)에게 맡겨서
순서대로 진행하고, 각 마일스톤 끝에 qa 에이전트로 점검해줘.
디자인 이미지는 아직 없으니 플레이스홀더로 진행해.
```

## 2.5 기능을 추가·변경할 때
```
/update-spec 으로 F07 "<기능>" 스펙을 먼저 만들어줘. 열린 질문은 나한테 물어봐.
```

## 3. 디자인 넘길 때
`Assets/Themes/sixpack/`에 규격대로 PNG를 넣고:
```
/add-theme sixpack
```

## 4. 제출 전
```
/release-check
```

## 사용량 아끼는 팁
- 큰 작업은 마일스톤 단위로 끊어서 요청하고, 끝나면 `/clear`로 대화를 비운 뒤 다음 마일스톤 시작 (맥락은 CLAUDE.md와 PROGRESS.md가 이어줌)
- 서브에이전트를 동시에 여러 개 띄우면 빠르지만 사용량이 몇 배로 듭니다. 한도가 빠듯할 땐 순서대로.
- 단순 작업(문구 수정, 색 변경)은 에이전트 거치지 말고 바로 요청
