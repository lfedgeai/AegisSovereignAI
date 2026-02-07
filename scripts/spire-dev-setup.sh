#!/bin/bash
set -e

# Create a temporary SPIRE development environment for working on overlay patches
# This generates a fork with patches applied so you can develop with IDE support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEV_DIR="$PROJECT_ROOT/build/spire-dev"
OVERLAY_DIR="$PROJECT_ROOT/spire-overlay"

SPIRE_VERSION="${SPIRE_VERSION:-v1.10.3}"
SPIRE_REPO="https://github.com/spiffe/spire.git"

echo "🔧 Setting up SPIRE development environment"
echo "   Version: ${SPIRE_VERSION}"
echo "   Location: ${DEV_DIR}"
echo ""

# Check if dev environment already exists
if [ -d "$DEV_DIR" ]; then
    echo "⚠️  Development environment already exists!"
    echo "   Remove it first with: rm -rf $DEV_DIR"
    echo "   Or use: ./scripts/spire-dev-cleanup.sh"
    exit 1
fi

# Create dev directory
mkdir -p "$DEV_DIR"
cd "$DEV_DIR"

# Clone SPIRE
echo "📥 Cloning SPIRE ${SPIRE_VERSION}..."
git clone --depth 1 --branch "${SPIRE_VERSION}" "${SPIRE_REPO}" spire
cd spire

# Create a development branch
git checkout -b aegis-dev

# Apply patches
echo ""
echo "🔨 Applying overlay patches..."

# Apply proto patches
if [ -d "$OVERLAY_DIR/proto-patches/files" ]; then
    echo "   📝 Copying proto extensions..."
    cp -r "$OVERLAY_DIR/proto-patches/files/"* .
fi

# Apply core patches
if [ -d "$OVERLAY_DIR/core-patches" ]; then
    echo "   🔧 Applying core patches..."
    for patch in "$OVERLAY_DIR/core-patches"/*.patch; do
        if [ -f "$patch" ]; then
            echo "      - $(basename $patch)"
            git apply "$patch" || {
                echo "❌ Failed to apply patch: $patch"
                echo "   Fix conflicts manually, then run: git add . && git commit"
                exit 1
            }
        fi
    done
fi

# Copy plugins
if [ -d "$OVERLAY_DIR/plugins" ]; then
    echo "   🔌 Copying custom plugins..."
    mkdir -p pkg/server/plugin
    mkdir -p pkg/agent/plugin
    cp -r "$OVERLAY_DIR/plugins"/* pkg/server/plugin/ 2>/dev/null || true
fi

# Copy packages
if [ -d "$OVERLAY_DIR/common-packages" ]; then
    echo "   📦 Copying common packages..."
    cp -r "$OVERLAY_DIR/common-packages"/* pkg/common/ 2>/dev/null || true
fi

if [ -d "$OVERLAY_DIR/cache-packages" ]; then
    echo "   💾 Copying cache packages..."
    cp -r "$OVERLAY_DIR/cache-packages"/* pkg/server/cache/ 2>/dev/null || true
fi

# Commit all changes
git add -A
git commit -m "Apply Aegis overlay for development

Applied from: $OVERLAY_DIR
Patches: $(ls $OVERLAY_DIR/core-patches/*.patch 2>/dev/null | wc -l | tr -d ' ')
"

echo ""
echo "✅ Development environment ready!"
echo ""
echo "📂 Location: $DEV_DIR/spire"
echo ""
echo "Next steps:"
echo "  1. cd $DEV_DIR/spire"
echo "  2. Make your changes"
echo "  3. Test: make build"
echo "  4. Extract: ../../scripts/spire-dev-extract.sh"
echo "  5. Cleanup: ../../scripts/spire-dev-cleanup.sh"
echo ""
