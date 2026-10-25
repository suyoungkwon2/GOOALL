#!/bin/bash
# 서명 Release 아카이브 → App Store Connect(TestFlight) 업로드. docs/TEST_PLAN.md 7절.
# 서명은 Xcode 자동 서명 + App Store Connect API 키 (인증서·프로비저닝 파일을 따로 관리하지 않는다).
#
# 필요한 환경변수:
#   ASC_KEY_ID, ASC_ISSUER_ID  App Store Connect → Users and Access → Integrations → App Store Connect API
#   ASC_KEY_P8                 .p8 파일 내용 (-----BEGIN PRIVATE KEY----- 포함)
# 선택:
#   VERSION_TAG   v0.1.0 형식이면 MARKETING_VERSION=0.1.0 (없으면 프로젝트 값 유지)
#   BUILD_NUMBER  CURRENT_PROJECT_VERSION (없으면 UTC 현재 시각 yyyyMMddHHmm — CI·로컬 모두 이 형식으로 통일해 번호가 거꾸로 가지 않게 한다)
set -euo pipefail
cd "$(dirname "$0")/.."

for name in ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8; do
  if [ -z "${!name:-}" ]; then
    echo "❌ $name 가 없습니다. GitHub 저장소 Settings → Secrets and variables → Actions에 등록하세요 (docs/USER_TODO.md F절)."
    exit 1
  fi
done

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
KEY_PATH="$WORK_DIR/AuthKey_${ASC_KEY_ID}.p8"
printf '%s\n' "$ASC_KEY_P8" > "$KEY_PATH"
chmod 600 "$KEY_PATH"

AUTH_ARGS=(
  -allowProvisioningUpdates
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
)

VERSION_ARGS=("CURRENT_PROJECT_VERSION=${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}")
if [[ "${VERSION_TAG:-}" =~ ^v([0-9]+(\.[0-9]+){1,2})$ ]]; then
  VERSION_ARGS+=("MARKETING_VERSION=${BASH_REMATCH[1]}")
fi
echo "▶︎ Version: ${VERSION_ARGS[*]}"

ARCHIVE_PATH="$WORK_DIR/GOOALL.xcarchive"

echo "▶︎ Archive (Release, 서명)"
xcodebuild archive \
  -project GOOALL.xcodeproj \
  -scheme GOOALL \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  "${AUTH_ARGS[@]}" \
  "${VERSION_ARGS[@]}" \
  -quiet

echo "▶︎ Export + TestFlight 업로드"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist scripts/ExportOptions.plist \
  -exportPath "$WORK_DIR/export" \
  "${AUTH_ARGS[@]}"

echo "✅ 업로드 완료. App Store Connect → TestFlight에서 처리 상태를 확인하세요 (보통 10~30분)."
