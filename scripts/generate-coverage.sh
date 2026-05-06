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
SIMULATOR="platform=iOS Simulator,name=iPhone 16,OS=latest"

echo "▶ Running tests with coverage..."
xcodebuild test \
  -project Stride.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$SIMULATOR" \
  -derivedDataPath "$DERIVED_DATA" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" \
  | xcpretty || true

echo "▶ Extracting coverage JSON..."
xcrun xccov view \
  --report \
  --files-for-target Stride.app \
  --json \
  "$RESULT_BUNDLE" > /tmp/coverage.json

echo "▶ Converting to SonarCloud generic XML..."
python3 scripts/xccov_to_sonar.py /tmp/coverage.json "$OUTPUT"

echo "✓ Coverage report written to $OUTPUT"
