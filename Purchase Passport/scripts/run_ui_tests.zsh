#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$APP_DIR/.." && pwd)"

SCHEME="Purchase Passport"
DESTINATION="platform=macOS"
PROJECT="$REPO_DIR/Purchase Passport.xcodeproj"
BUNDLE_ID="org.topository.Purchase-Passport"
APP_NAME="Purchase Passport"

# Keep build artifacts off Desktop/file-provider managed paths.
# This avoids code-sign failures from inherited extended attributes.
BUILD_ROOT="/private/tmp/PurchasePassport-test-artifacts"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
RESULT_BUNDLE_DIR="$BUILD_ROOT/Results"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RESULT_BUNDLE_PATH="$RESULT_BUNDLE_DIR/Test-${TIMESTAMP}.xcresult"

MODE="${1:-single}"

# Prevent macOS metadata from being copied into bundles where codesign rejects it.
export COPYFILE_DISABLE=1

# Start each run from a clean build tree to avoid stale metadata in bundles.
rm -rf "$DERIVED_DATA_PATH"
mkdir -p "$DERIVED_DATA_PATH" "$RESULT_BUNDLE_DIR"

LOG_PATH="$RESULT_BUNDLE_DIR/run-${TIMESTAMP}.log"
touch "$LOG_PATH"

if [[ ! -d "$PROJECT" ]]; then
  echo "Error: Xcode project not found at: $PROJECT"
  exit 1
fi

echo "== Purchase Passport UI test runner ==" | tee -a "$LOG_PATH"
echo "project:        $PROJECT" | tee -a "$LOG_PATH"
echo "scheme:         $SCHEME" | tee -a "$LOG_PATH"
echo "destination:    $DESTINATION" | tee -a "$LOG_PATH"
echo "derived data:   $DERIVED_DATA_PATH" | tee -a "$LOG_PATH"
echo "result bundle:  $RESULT_BUNDLE_PATH" | tee -a "$LOG_PATH"
echo "log file:       $LOG_PATH" | tee -a "$LOG_PATH"
echo "mode:           $MODE" | tee -a "$LOG_PATH"
echo "timestamp:      $TIMESTAMP" | tee -a "$LOG_PATH"

# Ensure stale app instances from previous UI test runs don't block launch.
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
pkill -f "$BUNDLE_ID" >/dev/null 2>&1 || true
sleep 1

# Strip Finder/resource-fork metadata that can break codesign in test bundles.
xattr -cr "$APP_DIR" "$REPO_DIR/Purchase PassportTests" "$REPO_DIR/Purchase PassportUITests" >/dev/null 2>&1 || true
xattr -cr "$BUILD_ROOT" >/dev/null 2>&1 || true

COMMON_ARGS=(
  test
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  -resultBundlePath "$RESULT_BUNDLE_PATH"
)

if [[ "$MODE" == "single" ]]; then
  echo "Running targeted failing UI test..." | tee -a "$LOG_PATH"
  XCODEBUILD_ARGS=(
    "${COMMON_ARGS[@]}"
    -only-testing:"Purchase PassportUITests/Purchase_PassportUITests/testCanOpenAllPurchasesAndSeeSeededPurchase"
  )
elif [[ "$MODE" == "all-ui" ]]; then
  echo "Running full UI test target..." | tee -a "$LOG_PATH"
  XCODEBUILD_ARGS=(
    "${COMMON_ARGS[@]}"
    -only-testing:"Purchase PassportUITests"
  )
else
  echo "Usage: ./scripts/run_ui_tests.zsh [single|all-ui]"
  exit 1
fi

(
  xcodebuild "${XCODEBUILD_ARGS[@]}" 2>&1 | tee -a "$LOG_PATH"
) &
XCODEBUILD_PID=$!

while kill -0 "$XCODEBUILD_PID" >/dev/null 2>&1; do
  echo "[runner] $(date '+%H:%M:%S') tests still running..." | tee -a "$LOG_PATH"
  sleep 15
done

wait "$XCODEBUILD_PID"
XCODEBUILD_EXIT=$?

echo "Result bundle: $RESULT_BUNDLE_PATH"
echo "Run log: $LOG_PATH"
exit "$XCODEBUILD_EXIT"
