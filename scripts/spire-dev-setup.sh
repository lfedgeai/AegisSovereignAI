#!/bin/bash
set -e

# Create a temporary SPIRE development environment for working on overlay patches
# This generates a fork with patches applied so you can develop with IDE support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEV_DIR="$PROJECT_ROOT/build/spire-dev"
OVERLAY_DIR="$PROJECT_ROOT/spire-overlay"

SPIRE_VERSION="${SPIRE_VERSION:-v1.14.1}"
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

# Apply proto patches (copy extended spire-api-sdk files)
if [ -d "$OVERLAY_DIR/proto-patches/files" ]; then
    echo "   📝 Copying proto extensions..."
    cp -r "$OVERLAY_DIR/proto-patches/files/"* .
fi

# Apply common-packages (pluginconf, tlspolicy, utilcast) if present
for pkg_dir in tlspolicy pluginconf utilcast; do
    if [ -d "$OVERLAY_DIR/common-packages/$pkg_dir" ]; then
        mkdir -p "pkg/common/$pkg_dir"
        cp -r "$OVERLAY_DIR/common-packages/$pkg_dir"/* "pkg/common/$pkg_dir/"
        echo "   📦 Installed common-packages/$pkg_dir"
    fi
done

# Apply cache-packages if present
if [ -d "$OVERLAY_DIR/cache-packages/nodecache" ]; then
    mkdir -p pkg/server/cache/nodecache
    cp -r "$OVERLAY_DIR/cache-packages/nodecache"/* pkg/server/cache/nodecache/
    echo "   💾 Installed cache-packages/nodecache"
fi

# Apply core patches
if [ -d "$OVERLAY_DIR/core-patches" ]; then
    echo "   🔧 Applying core patches..."
    for patch in "$OVERLAY_DIR/core-patches"/*.patch; do
        if [ -f "$patch" ]; then
            echo "      - $(basename $patch)"
            git apply "$patch" 2>/dev/null || {
                echo "      ⚠️  $(basename $patch) conflicts — trying 3-way merge"
                git apply --3way "$patch" || {
                    echo "❌ Failed to apply patch: $patch"
                    echo "   Fix conflicts manually then: git add . && git commit"
                    exit 1
                }
            }
        fi
    done
fi

# Install server support modules (same paths as spire-build.sh)
echo "   🔌 Installing plugins and modules..."
if [ -d "$OVERLAY_DIR/plugins/server-keylime" ]; then
    mkdir -p pkg/server/keylime
    cp -r "$OVERLAY_DIR/plugins/server-keylime"/* pkg/server/keylime/
    echo "      ✓ server-keylime"
fi
if [ -d "$OVERLAY_DIR/plugins/server-policy" ]; then
    mkdir -p pkg/server/policy
    cp -r "$OVERLAY_DIR/plugins/server-policy"/* pkg/server/policy/
    echo "      ✓ server-policy"
fi
if [ -d "$OVERLAY_DIR/plugins/server-unifiedidentity" ]; then
    mkdir -p pkg/server/unifiedidentity
    cp -r "$OVERLAY_DIR/plugins/server-unifiedidentity"/* pkg/server/unifiedidentity/
    echo "      ✓ server-unifiedidentity"
fi
if [ -d "$OVERLAY_DIR/plugins/agent-nodeattestor-unifiedidentity" ]; then
    mkdir -p pkg/agent/plugin/nodeattestor/unifiedidentity
    cp -r "$OVERLAY_DIR/plugins/agent-nodeattestor-unifiedidentity"/* \
          pkg/agent/plugin/nodeattestor/unifiedidentity/
    echo "      ✓ agent-nodeattestor-unifiedidentity"
fi
if [ -d "$OVERLAY_DIR/plugins/server-credentialcomposer-unifiedidentity" ]; then
    mkdir -p pkg/server/plugin/credentialcomposer/unifiedidentity
    cp -r "$OVERLAY_DIR/plugins/server-credentialcomposer-unifiedidentity"/* \
          pkg/server/plugin/credentialcomposer/unifiedidentity/
    echo "      ✓ server-credentialcomposer-unifiedidentity"
fi

# Install catalog patches (replace upstream catalog files with overlay versions)
echo "   📋 Patching plugin catalogs..."
if [ -f "$OVERLAY_DIR/catalog-patches/server-credentialcomposer-catalog.go" ]; then
    cp "$OVERLAY_DIR/catalog-patches/server-credentialcomposer-catalog.go" \
       pkg/server/catalog/credentialcomposer.go
    echo "      ✓ server catalog (credentialcomposer)"
fi
if [ -f "$OVERLAY_DIR/catalog-patches/agent-nodeattestor-catalog.go" ]; then
    cp "$OVERLAY_DIR/catalog-patches/agent-nodeattestor-catalog.go" \
       pkg/agent/catalog/nodeattestor.go
    echo "      ✓ agent catalog (nodeattestor)"
fi

# Install new packages (packages that exist in the Aegis fork but not in vanilla SPIRE)
echo "   📦 Installing new packages..."
if [ -d "$OVERLAY_DIR/new-packages" ]; then
    find "$OVERLAY_DIR/new-packages" -type f | while read -r src; do
        rel="${src#$OVERLAY_DIR/new-packages/}"
        dst_dir="$(dirname "$rel")"
        mkdir -p "$dst_dir"
        cp "$src" "$rel"
        echo "      ✓ $rel"
    done
fi

# Commit all changes
git add -A
git commit -m "Apply Aegis overlay for development

Applied from: $OVERLAY_DIR
Version: ${SPIRE_VERSION}
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
echo "  4. Extract changes:  cd $PROJECT_ROOT && ./scripts/spire-dev-extract.sh"
echo "  5. Test build:        ./scripts/spire-build.sh"
echo "  6. Commit patches:    git add spire-overlay && git commit"
echo "  7. Cleanup dev env:   ./scripts/spire-dev-cleanup.sh"
echo ""
