#!/usr/bin/env bash
# Runs tests with coverage and converts the result to SonarCloud's
# generic coverage XML format. Requires Xcode + xcodebuild in PATH.
#
# Usage: ./scripts/generate-coverage.sh
# Output: sonar-coverage.xml at repo root

set -euo pipefail

SCHEME="Stride"
DERIVED_DATA="DerivedData"
RESULT_BUNDLE="TestResults.xcresult"
OUTPUT="sonar-coverage.xml"

# Dynamically pick the first available iPhone simulator so this works
# on any runner without hardcoding an OS version.
echo "▶ Resolving simulator..."
SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    if 'iOS' not in runtime:
        continue
    for device in devices:
        if device['isAvailable'] and 'iPhone' in device['name']:
            print(device['udid'])
            sys.exit(0)
sys.exit(1)
")
echo "  Using simulator: $SIMULATOR_ID"

echo "▶ Running tests with coverage..."
set +e
xcodebuild test \
  -project Stride.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" \
  2>&1 | grep -E "(^(Build|Compile|Test|FAILED|Executed)| error:| warning:|Testing)" || true
XCODEBUILD_EXIT=${PIPESTATUS[0]}
set -e
if [ "$XCODEBUILD_EXIT" -ne 0 ]; then
  echo "✗ xcodebuild exited with code $XCODEBUILD_EXIT"
  exit "$XCODEBUILD_EXIT"
fi

echo "▶ Extracting coverage JSON..."
xcrun xccov view \
  --report \
  --files-for-target Stride.app \
  --json \
  "$RESULT_BUNDLE" > /tmp/coverage.json

echo "▶ Converting to SonarCloud generic XML..."
python3 scripts/xccov_to_sonar.py /tmp/coverage.json "$OUTPUT"

echo "✓ Coverage report written to $OUTPUT"
