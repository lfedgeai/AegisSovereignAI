#!/bin/bash
set -e

# Build SPIRE from the committed spire-fork/ source tree.
#
# The spire-fork/ directory contains the full AegisSovereignAI-modified SPIRE
# source (cloned from upstream v1.14.1 with all overlay patches applied and
# committed directly).  Anyone can edit the source files in spire-fork/ and
# run this script to rebuild without needing patch tooling.
#
# Usage:
#   ./scripts/spire-fork-build.sh            # build and copy binaries
#   SPIRE_MODE=overlay ./scripts/spire-build.sh  # use patch-based overlay instead
#
# Output: build/spire-binaries/spire-server and spire-agent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FORK_DIR="$PROJECT_ROOT/spire-fork"
FORK_SDK_DIR="$PROJECT_ROOT/spire-fork-sdk"
BUILD_DIR="$PROJECT_ROOT/build"
BINARY_DIR="$BUILD_DIR/spire-binaries"

# ──────────────────────────────────────────────────────────────────────────────
echo "🔨 Building SPIRE from committed fork (spire-fork/)"
echo "   Edit files in spire-fork/ directly, then re-run this script."
echo ""

if [ ! -d "$FORK_DIR" ]; then
    echo "❌ spire-fork/ directory not found at $FORK_DIR"
    echo "   Run 'SPIRE_MODE=overlay scripts/spire-build.sh' to assemble it first,"
    echo "   or check out the branch that includes the spire-fork/ commit."
    exit 1
fi

if [ ! -d "$FORK_SDK_DIR" ]; then
    echo "❌ spire-fork-sdk/ directory not found at $FORK_SDK_DIR"
    echo "   It should be in the same commit as spire-fork/."
    exit 1
fi

# ── Verify local dependencies exist ──────────────────────────────────────────
# go-spiffe and spire-fork-sdk are referenced as relative paths in go.mod;
# confirm they are present before attempting to build.
if [ ! -d "$PROJECT_ROOT/hybrid-cloud-poc/go-spiffe" ]; then
    echo "❌ hybrid-cloud-poc/go-spiffe not found — ensure the full repo is checked out."
    exit 1
fi

cd "$FORK_DIR"
echo "   ✓ local dependencies found"
echo ""

# ── Build ─────────────────────────────────────────────────────────────────────
# Use 'make build' so the Makefile's go-check target manages the Go toolchain
# (downloading the version pinned in spire-fork/.go-version if needed),
# exactly as the overlay mode does.  This avoids GOTOOLCHAIN mismatches when
# the system Go is older than what transitive dependencies require.
echo "🏗️  Compiling SPIRE binaries (make build)..."
make build
echo "   ✓ Build complete"
echo ""

# ── Copy binaries ─────────────────────────────────────────────────────────────
mkdir -p "$BINARY_DIR"
cp bin/spire-server "$BINARY_DIR/spire-server"
cp bin/spire-agent  "$BINARY_DIR/spire-agent"

echo "✅ Binaries ready:"
echo "   $BINARY_DIR/spire-server"
echo "   $BINARY_DIR/spire-agent"

# ── Build metadata ────────────────────────────────────────────────────────────
mkdir -p "$BUILD_DIR"
{
    echo "SPIRE_MODE=fork"
    echo "SOURCE=spire-fork/"
    echo "BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "SPIRE_VERSION=v1.14.1"
} > "$BUILD_DIR/BUILD_INFO.txt"
