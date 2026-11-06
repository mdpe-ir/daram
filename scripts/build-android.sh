#!/usr/bin/env bash
# Convenience wrapper for the Android release build.
# Usage: ./scripts/build-android.sh [apk|split|aab] [--clean]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/release.sh" --android "$@"
