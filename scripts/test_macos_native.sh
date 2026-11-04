#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/wof-native-tests.XXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
export NAI_STUDIO_SANDBOX="$scratch/profile"
export TEST_RUNNER_NAI_STUDIO_SANDBOX="$NAI_STUDIO_SANDBOX"
mkdir -p "$NAI_STUDIO_SANDBOX"
xcodebuild test -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination "platform=macOS,arch=$(uname -m)" \
  -parallel-testing-enabled NO -only-testing:RunnerTests \
  "WOF_XCTEST_SANDBOX=$NAI_STUDIO_SANDBOX" CODE_SIGN_IDENTITY=-
