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
echo "💾 Backing up current overlay to: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r "$OVERLAY_DIR/core-patches" "$BACKUP_DIR/" 2>/dev/null || true

# Regenerate patches
echo ""
echo "🔨 Regenerating patches..."

# Get the base commit — the "Apply Aegis overlay for development" commit made by spire-dev-setup.sh.
# Everything AFTER that commit represents the developer's own edits.
BASE_COMMIT=$(git log --grep="Apply Aegis overlay for development" --format="%H" | head -1)
if [ -z "$BASE_COMMIT" ]; then
    echo "❌ Could not find base commit"
    echo "   Are you in the correct repository? Run spire-dev-setup.sh first."
    exit 1
fi

# PARENT_COMMIT is vanilla SPIRE before any overlay was applied.
# Diffing PARENT_COMMIT..HEAD gives all overlay customisations including the
# developer's most recent edits — which is exactly what we want to capture.
PARENT_COMMIT="${BASE_COMMIT}^"

# ── Core patches ────────────────────────────────────────────────────────────
# For each existing patch file, parse the list of files it covers (from its
# "diff --git a/... b/..." headers), then re-diff those exact paths from
# PARENT_COMMIT to HEAD. This generic approach handles any number of patches
# without needing per-patch hardcoded path lists.
echo "   🔧 Regenerating core patches..."
for patch in "$OVERLAY_DIR/core-patches"/*.patch; do
    [ -f "$patch" ] || continue
    patch_name=$(basename "$patch")

    # Collect the set of SPIRE-relative file paths covered by this patch
    files=$(grep "^diff --git" "$patch" | awk '{print $3}' | sed 's|^a/||')
    if [ -z "$files" ]; then
        echo "      ⚠️  $patch_name has no file paths — skipping regeneration"
        continue
    fi

    # Re-diff and overwrite the patch file
    # shellcheck disable=SC2086  # word splitting of $files is intentional
    git diff "$PARENT_COMMIT" HEAD -- $files > "$patch"
    lines=$(wc -l < "$patch")
    echo "      ✅ $patch_name ($lines lines)"
done

# ── Plugins ─────────────────────────────────────────────────────────────────
echo "   🔌 Extracting plugins..."

declare -A PLUGIN_MAP=(
    ["pkg/server/keylime"]="plugins/server-keylime"
    ["pkg/server/policy"]="plugins/server-policy"
    ["pkg/server/unifiedidentity"]="plugins/server-unifiedidentity"
    ["pkg/agent/plugin/nodeattestor/unifiedidentity"]="plugins/agent-nodeattestor-unifiedidentity"
    ["pkg/server/plugin/credentialcomposer/unifiedidentity"]="plugins/server-credentialcomposer-unifiedidentity"
)

for spire_path in "${!PLUGIN_MAP[@]}"; do
    overlay_path="${PLUGIN_MAP[$spire_path]}"
    if [ -d "$spire_path" ]; then
        mkdir -p "$OVERLAY_DIR/$overlay_path"
        cp -r "$spire_path"/. "$OVERLAY_DIR/$overlay_path/"
        echo "      ✅ $overlay_path"
    fi
done

# ── Catalog patches ──────────────────────────────────────────────────────────
echo "   📋 Extracting catalog patches..."
if [ -f "pkg/server/catalog/credentialcomposer.go" ]; then
    cp "pkg/server/catalog/credentialcomposer.go" \
       "$OVERLAY_DIR/catalog-patches/server-credentialcomposer-catalog.go"
    echo "      ✅ server-credentialcomposer-catalog.go"
fi
if [ -f "pkg/agent/catalog/nodeattestor.go" ]; then
    cp "pkg/agent/catalog/nodeattestor.go" \
       "$OVERLAY_DIR/catalog-patches/agent-nodeattestor-catalog.go"
    echo "      ✅ agent-nodeattestor-catalog.go"
fi

# ── New packages ─────────────────────────────────────────────────────────────
# New packages are files that exist in the Aegis overlay but not in vanilla SPIRE.
# They are tracked by the new-packages/ directory in the overlay; copy them back.
echo "   📦 Extracting new packages..."
if [ -d "$OVERLAY_DIR/new-packages" ]; then
    find "$OVERLAY_DIR/new-packages" -type f | while read -r overlay_file; do
        rel="${overlay_file#$OVERLAY_DIR/new-packages/}"
        if [ -f "$rel" ]; then
            cp "$rel" "$overlay_file"
            echo "      ✅ $rel"
        fi
    done
fi

echo ""
echo "✅ Extraction complete!"
echo ""
echo "📊 Summary:"
echo "   Backup: $BACKUP_DIR"
echo "   Core patches updated in: $OVERLAY_DIR/core-patches/"
echo "   Plugins updated in:      $OVERLAY_DIR/plugins/"
echo "   Catalog patches in:      $OVERLAY_DIR/catalog-patches/"
echo "   New packages in:         $OVERLAY_DIR/new-packages/"
echo ""
echo "Next steps:"
echo "   1. Review changes: git diff spire-overlay/ (from project root)"
echo "   2. Test build:     cd $PROJECT_ROOT && ./scripts/spire-build.sh"
echo "   3. Commit:         git add spire-overlay && git commit"
echo "   4. Cleanup dev:    ./scripts/spire-dev-cleanup.sh"
echo ""
