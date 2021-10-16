#!/usr/bin/env bash
set -e
cd "$(dirname -- "${BASH_SOURCE[0]}")"

flutter clean
flutter build apk \
    --release \
    --dart-define=APP_BUILD_TIMESTAMP="$(date +%s)" \
    --dart-define=APP_GIT_HASH="$(git rev-parse HEAD)" \
    --split-debug-info=build/debug_info
