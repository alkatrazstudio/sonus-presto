#!/usr/bin/env bash
set -e
cd "$(dirname -- "${BASH_SOURCE[0]}")"

flutter clean
flutter build appbundle \
    --release \
    --dart-define=APP_BUILD_TIMESTAMP="$(date +%s)" \
    --dart-define=APP_GIT_HASH="$(git rev-parse HEAD)"

if [[ "$1" == "--upload" ]]
then
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    bundle exec fastlane upload_play
fi
