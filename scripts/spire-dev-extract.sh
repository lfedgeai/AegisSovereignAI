#!/bin/bash
set -e

# Extract changes from development environment back to overlay patches
# Run this after making changes in build/spire-dev/spire

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEV_DIR="$PROJECT_ROOT/build/spire-dev/spire"
OVERLAY_DIR="$PROJECT_ROOT/spire-overlay"

echo "🔍 Extracting changes from development environment"
echo ""

# Verify dev environment exists
if [ ! -d "$DEV_DIR" ]; then
    echo "❌ Development environment not found: $DEV_DIR"
    echo "   Run ./scripts/spire-dev-setup.sh first"
    exit 1
fi

cd "$DEV_DIR"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  You have uncommitted changes!"
    echo "   Commit them first: cd $DEV_DIR && git add -A && git commit -m 'Your changes'"
    exit 1
fi

# Create backup of current patches
BACKUP_DIR="$OVERLAY_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
echo "💾 Backing up current patches to: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r "$OVERLAY_DIR/core-patches" "$BACKUP_DIR/" 2>/dev/null || true

# Regenerate patches
echo ""
echo "🔨 Regenerating patches..."

# Get the base commit (before our changes)
BASE_COMMIT=$(git log --grep="Apply Aegis overlay for development" --format="%H" | head -1)
if [ -z "$BASE_COMMIT" ]; then
    echo "❌ Could not find base commit"
    echo "   Are you in the correct repository?"
    exit 1
fi

PARENT_COMMIT="${BASE_COMMIT}^"

# Extract proto changes
echo "   📝 Extracting proto changes..."
PROTO_DIFF=$(git diff "$PARENT_COMMIT" HEAD -- proto/spire/api/)
if [ -n "$PROTO_DIFF" ]; then
    # Update proto-patches directory
    git diff "$PARENT_COMMIT" HEAD -- proto/spire/api/ > /tmp/proto-changes.patch
    echo "   ✅ Proto changes detected"
else
    echo "   ℹ️  No proto changes"
fi

# Extract core patches (everything except proto and plugins)
echo "   🔧 Extracting core patches..."

# Server API patch
git diff "$PARENT_COMMIT" HEAD -- pkg/server/api/ > "$OVERLAY_DIR/core-patches/server-api.patch"
echo "      ✅ server-api.patch ($(wc -l < $OVERLAY_DIR/core-patches/server-api.patch) lines)"

# Server endpoints patch
git diff "$PARENT_COMMIT" HEAD -- pkg/server/endpoints/ > "$OVERLAY_DIR/core-patches/server-endpoints.patch"
echo "      ✅ server-endpoints.patch ($(wc -l < $OVERLAY_DIR/core-patches/server-endpoints.patch) lines)"

# Feature flags patch
git diff "$PARENT_COMMIT" HEAD -- cmd/ pkg/common/fflag/ > "$OVERLAY_DIR/core-patches/feature-flags.patch"
echo "      ✅ feature-flags.patch ($(wc -l < $OVERLAY_DIR/core-patches/feature-flags.patch) lines)"

# Extract custom plugins
echo "   🔌 Extracting plugins..."
if [ -d "pkg/server/plugin/credentialcomposer/unifiedidentity" ]; then
    mkdir -p "$OVERLAY_DIR/plugins/server-credentialcomposer-unifiedidentity"
    cp -r pkg/server/plugin/credentialcomposer/unifiedidentity/* \
        "$OVERLAY_DIR/plugins/server-credentialcomposer-unifiedidentity/"
    echo "      ✅ unifiedidentity plugin"
fi

# Extract packages
echo "   📦 Extracting packages..."
if [ -d "pkg/server/cache/nodecache" ]; then
    mkdir -p "$OVERLAY_DIR/cache-packages/nodecache"
    cp -r pkg/server/cache/nodecache/* "$OVERLAY_DIR/cache-packages/nodecache/"
    echo "      ✅ nodecache"
fi

echo ""
echo "✅ Extraction complete!"
echo ""
echo "📊 Summary:"
echo "   Backup: $BACKUP_DIR"
echo "   Updated patches in: $OVERLAY_DIR/core-patches/"
echo ""
echo "Next steps:"
echo "   1. Review changes: git diff $OVERLAY_DIR"
echo "   2. Test build: ./scripts/spire-build.sh"
echo "   3. Commit changes: git add spire-overlay && git commit"
echo "   4. Cleanup dev env: ./scripts/spire-dev-cleanup.sh"
echo ""
