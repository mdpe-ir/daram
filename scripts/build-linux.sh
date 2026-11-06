#!/usr/bin/env bash
# Convenience wrapper for the production Linux build.
# Usage: ./scripts/build-linux.sh [--clean]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/release.sh" --linux "$@"
