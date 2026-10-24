#!/usr/bin/env bash
# GOOALL CI: 로컬과 GitHub Actions가 같은 순서로 검사한다 (docs/TEST_PLAN.md 2절).
#   1. 위젯 빌드  2. 단위·렌더 테스트  3. Release 빌드  4. Release에 DEBUG 코드가 없는지
# 사용: scripts/ci.sh   (환경변수 SIMULATOR_ID, OUTPUT_DIR로 덮어쓸 수 있음)
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="GOOALL.xcodeproj"
OUTPUT_DIR="${OUTPUT_DIR:-build/ci}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"  # 절대경로로 (테스트 러너에 넘기기 위해)
DERIVED_DATA="$OUTPUT_DIR/DerivedData"
RESULT_BUNDLE="$OUTPUT_DIR/TestResults.xcresult"
SNAPSHOT_DIR="$OUTPUT_DIR/widget-snapshots"
# 서명 없이 빌드한다 (CI에는 인증서가 없음. 시뮬레이터 테스트에는 필요 없음)
COMMON=(-project "$PROJECT" -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO)

mkdir -p "$OUTPUT_DIR"
rm -rf "$RESULT_BUNDLE" "$SNAPSHOT_DIR"

if [[ -z "${SIMULATOR_ID:-}" ]]; then
  # 사용 가능한 iOS 26 이상 iPhone 시뮬레이터 중 첫 번째
  SIMULATOR_ID="$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
data = json.load(sys.stdin)["devices"]
for runtime, devices in sorted(data.items(), reverse=True):
    m = re.search(r"iOS-(\d+)", runtime)
    if not m or int(m.group(1)) < 26:
        continue
    for d in devices:
        if d["name"].startswith("iPhone"):
            print(d["udid"]); sys.exit(0)
sys.exit("no iOS 26+ iPhone simulator found")
')"
fi
echo "▶︎ Simulator: $SIMULATOR_ID"
xcodebuild -version

echo "▶︎ 1/4 Widget build"
xcodebuild "${COMMON[@]}" -scheme widgetExtension -destination "generic/platform=iOS Simulator" build | tail -3

echo "▶︎ 2/4 Unit & render tests"
TEST_RUNNER_SNAPSHOT_DIR="$SNAPSHOT_DIR" xcodebuild "${COMMON[@]}" -scheme GOOALL \
  -destination "id=$SIMULATOR_ID" -resultBundlePath "$RESULT_BUNDLE" \
  -only-testing:GOOALLTests test | tail -5
xcrun xcresulttool get test-results summary --path "$RESULT_BUNDLE" | grep -E '"(result|passedTests|failedTests)"' | sort -u

echo "▶︎ 3/4 Release build"
xcodebuild "${COMMON[@]}" -scheme GOOALL -configuration Release -destination "generic/platform=iOS Simulator" build | tail -3

echo "▶︎ 4/4 No DEBUG code in Release (F02-R8)"
RELEASE_BINARY="$DERIVED_DATA/Build/Products/Release-iphonesimulator/GOOALL.app/GOOALL"
if strings "$RELEASE_BINARY" | grep -E "debugMockSteps|-debugOnboardingStep|Use fake steps"; then
  echo "✘ DEBUG-only code found in Release binary" >&2
  exit 1
fi

echo "✔ CI passed"
