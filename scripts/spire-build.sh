#!/bin/bash
set -e

# Build custom SPIRE with AegisSovereignAI modifications.
#
# All modifications live directly in spire-fork/ — edit files there and re-run.
# This script delegates to spire-fork-build.sh which runs 'make build' and
# copies the resulting binaries to build/spire-binaries/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -d "$PROJECT_ROOT/spire-fork" ]; then
    echo "❌ spire-fork/ directory not found under $PROJECT_ROOT"
    echo "   Make sure you are running from the AegisSovereignAI root."
    exit 1
fi

exec "$SCRIPT_DIR/spire-fork-build.sh" "$@"
