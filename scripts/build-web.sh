#!/usr/bin/env bash
# Convenience wrapper for the production web build.
# Usage: ./scripts/build-web.sh [--clean]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/release.sh" --web "$@"
