#!/bin/bash
set -e

# Build custom SPIRE with AegisSovereignAI modifications
# This script clones upstream SPIRE and applies our overlay patches

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
OVERLAY_DIR="$PROJECT_ROOT/spire-overlay"

# Configuration
SPIRE_VERSION="${SPIRE_VERSION:-v1.10.3}"
SPIRE_REPO="https://github.com/spiffe/spire.git"
SPIRE_API_SDK_REPO="https://github.com/spiffe/spire-api-sdk.git"

echo "🔨 Building custom SPIRE ${SPIRE_VERSION} with AegisSovereignAI modifications"
echo ""

# Verify overlay exists
if [ ! -d "$OVERLAY_DIR" ]; then
    echo "❌ Overlay directory not found: $OVERLAY_DIR"
    echo "   The spire-overlay directory contains our custom patches and plugins"
    exit 1
fi

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Clone SPIRE
echo "📦 Cloning SPIRE ${SPIRE_VERSION}..."
git clone --branch "$SPIRE_VERSION" --depth 1 "$SPIRE_REPO" "$BUILD_DIR/spire" --quiet

# Clone SPIRE API SDK (needed for proto files)
echo "📦 Cloning SPIRE API SDK..."
git clone --branch "$SPIRE_VERSION" --depth 1 "$SPIRE_API_SDK_REPO" "$BUILD_DIR/spire-api-sdk" --quiet

echo "   ✓ SPIRE and API SDK cloned"
echo ""

cd "$BUILD_DIR/spire"

# Apply proto patches - copy proto files from overlay
echo "🔧 Installing proto files..."
if [ -d "$OVERLAY_DIR/proto-patches/files/spire-api-sdk" ]; then
    echo "   Copying custom proto files to spire-api-sdk..."
    
    # Update spire-api-sdk proto files
    if [ -d "$OVERLAY_DIR/proto-patches/files/spire-api-sdk/spire/api/types" ]; then
        cp -v "$OVERLAY_DIR/proto-patches/files/spire-api-sdk/spire/api/types"/*.proto \
              "$BUILD_DIR/spire-api-sdk/proto/spire/api/types/" 2>/dev/null || true
    fi
    
    if [ -d "$OVERLAY_DIR/proto-patches/files/spire-api-sdk/spire/api/server/agent/v1" ]; then
        cp -v "$OVERLAY_DIR/proto-patches/files/spire-api-sdk/spire/api/server/agent/v1"/*.proto \
              "$BUILD_DIR/spire-api-sdk/proto/spire/api/server/agent/v1/" 2>/dev/null || true
    fi
    
    if [ -d "$OVERLAY_DIR/proto-patches/files/spire-api-sdk/spire/api/server/svid/v1" ]; then
        cp -v "$OVERLAY_DIR/proto-patches/files/spire-api-sdk/spire/api/server/svid/v1"/*.proto \
              "$BUILD_DIR/spire-api-sdk/proto/spire/api/server/svid/v1/" 2>/dev/null || true
    fi
    
    echo "   ✓ Proto files installed"
else
    echo "   ⚠️  No proto files found in overlay"
fi

# Apply core patches
echo ""
echo "🔧 Applying core patches..."

for patch_file in "$OVERLAY_DIR/core-patches"/*.patch; do
    if [ -f "$patch_file" ]; then
        patch_name=$(basename "$patch_file")
        echo "   Applying $patch_name..."
        
        if git apply --check "$patch_file" 2>/dev/null; then
            git apply "$patch_file" 2>&1 | grep -v "trailing whitespace" || true
            echo "   ✓ $patch_name applied"
        else
            echo "   ⚠️  $patch_name doesn't apply cleanly - trying 3-way merge..."
            git apply --3way "$patch_file" 2>&1 | grep -v "trailing whitespace" || {
                echo "   ❌ $patch_name failed!"
                echo "      Manual resolution needed in $BUILD_DIR/spire"
                exit 1
            }
        fi
    fi
done

# Install common and cache packages BEFORE applying patches
echo ""
echo "📦 Installing common and cache packages..."

if [ -d "$OVERLAY_DIR/common-packages/tlspolicy" ]; then
    mkdir -p pkg/common/tlspolicy
    cp -r "$OVERLAY_DIR/common-packages/tlspolicy"/* pkg/common/tlspolicy/
    echo "   ✓ tlspolicy package installed"
fi

if [ -d "$OVERLAY_DIR/common-packages/pluginconf" ]; then
    mkdir -p pkg/common/pluginconf
    cp -r "$OVERLAY_DIR/common-packages/pluginconf"/* pkg/common/pluginconf/
    echo "   ✓ pluginconf package installed"
fi

if [ -d "$OVERLAY_DIR/cache-packages/nodecache" ]; then
    mkdir -p pkg/server/cache/nodecache
    cp -r "$OVERLAY_DIR/cache-packages/nodecache"/* pkg/server/cache/nodecache/
    echo "   ✓ nodecache package installed"
fi

# Apply patches AFTER common packages are installed
echo ""
echo "🔧 Applying core patches..."

for patch_file in "$OVERLAY_DIR/core-patches"/*.patch; do
    if [ -f "$patch_file" ]; then
        patch_name=$(basename "$patch_file")
        echo "   Applying $patch_name..."
        
        if git apply --check "$patch_file" 2>/dev/null; then
            git apply "$patch_file" 2>&1 | grep -v "trailing whitespace" || true
            echo "   ✓ $patch_name applied"
        else
            echo "   ⚠️  $patch_name doesn't apply cleanly - trying 3-way merge..."
            git apply --3way "$patch_file" 2>&1 | grep -v "trailing whitespace" || {
                echo "   ❌ $patch_name failed!"
                echo "      Manual resolution needed in $BUILD_DIR/spire"
                exit 1
            }
        fi
    fi
done

# Install custom modules and plugins
echo ""
echo "📋 Installing custom modules and plugins..."

# Install server support modules (these are dependencies)
if [ -d "$OVERLAY_DIR/plugins/server-keylime" ]; then
    mkdir -p pkg/server/keylime
    cp -r "$OVERLAY_DIR/plugins/server-keylime"/* pkg/server/keylime/
    echo "   ✓ Keylime module installed"
fi

if [ -d "$OVERLAY_DIR/plugins/server-policy" ]; then
    mkdir -p pkg/server/policy
    cp -r "$OVERLAY_DIR/plugins/server-policy"/* pkg/server/policy/
    echo "   ✓ Policy module installed"
fi

if [ -d "$OVERLAY_DIR/plugins/server-unifiedidentity" ]; then
    mkdir -p pkg/server/unifiedidentity
    cp -r "$OVERLAY_DIR/plugins/server-unifiedidentity"/* pkg/server/unifiedidentity/
    echo "   ✓ Unified identity server module installed"
fi

# Install agent plugins
if [ -d "$OVERLAY_DIR/plugins/agent-nodeattestor-unifiedidentity" ]; then
    mkdir -p pkg/agent/plugin/nodeattestor/unifiedidentity
    cp -r "$OVERLAY_DIR/plugins/agent-nodeattestor-unifiedidentity"/* \
          pkg/agent/plugin/nodeattestor/unifiedidentity/
    echo "   ✓ Unified identity agent plugin installed"
fi

# Install server plugins
if [ -d "$OVERLAY_DIR/plugins/server-credentialcomposer-unifiedidentity" ]; then
    mkdir -p pkg/server/plugin/credentialcomposer/unifiedidentity
    cp -r "$OVERLAY_DIR/plugins/server-credentialcomposer-unifiedidentity"/* \
          pkg/server/plugin/credentialcomposer/unifiedidentity/
    echo "   ✓ Unified identity credential composer installed"
fi

# Update go.mod to use local spire-api-sdk
echo ""
echo "📝 Updating go.mod to use local spire-api-sdk..."
go mod edit -replace github.com/spiffe/spire-api-sdk=../spire-api-sdk

# Regenerate proto in spire-api-sdk first
echo ""
echo "🔄 Regenerating proto in spire-api-sdk..."
cd "$BUILD_DIR/spire-api-sdk"

# Add sovereignattestation.proto to Makefile if not already there
if ! grep -q "sovereignattestation.proto" Makefile; then
    echo "   Adding sovereignattestation.proto to Makefile..."
    sed -i.bak '/proto\/spire\/api\/types\/attestation.proto/a\
	proto/spire/api/types/sovereignattestation.proto \\
' Makefile
fi

if make generate 2>&1 | tee /tmp/spire-api-sdk-generate.log | grep -v "^go: downloading"; then
    echo "   ✓ API SDK proto files regenerated"
else
    echo "   ⚠️  API SDK proto generation had warnings"
fi
cd "$BUILD_DIR/spire"

# Register plugins in catalog
echo ""
echo "📝 Registering plugins in catalog..."

# Check if agent catalog needs update
AGENT_CATALOG="pkg/agent/plugin/nodeattestor/catalog.go"
if ! grep -q "unifiedidentity" "$AGENT_CATALOG" 2>/dev/null; then
    echo "   ⚠️  Agent catalog not auto-registered"
    echo "      You may need to manually add unifiedidentity to $AGENT_CATALOG"
else
    echo "   ✓ Agent catalog already includes unifiedidentity"
fi

# Regenerate proto (this will use our modified spire-api-sdk)
echo ""
echo "🔄 Regenerating proto files in SPIRE..."
if make generate 2>&1 | tee /tmp/spire-generate.log | grep -v "^go: downloading"; then
    echo "   ✓ Proto files regenerated"
else
    echo "   ⚠️  Proto generation had warnings (check /tmp/spire-generate.log)"
fi

# Download dependencies and tidy
echo ""
echo "📦 Downloading dependencies..."
go mod download 2>&1 | grep -v "^go: downloading" || true
go mod tidy 2>&1 | tee /tmp/spire-tidy.log

if grep -q "no matching versions" /tmp/spire-tidy.log; then
    echo "   ❌ go mod tidy failed - missing dependencies"
    echo "      Check /tmp/spire-tidy.log for details"
    cat /tmp/spire-tidy.log | grep "no matching versions"
    exit 1
fi

# Build
echo ""
echo "🏗️  Building SPIRE..."
echo "   This may take a few minutes..."

if make build 2>&1 | tee /tmp/spire-build.log | grep -E "(Building|Finished|Error|FAIL)"; then
    if grep -q "Error\|FAIL" /tmp/spire-build.log; then
        echo "   ❌ Build failed! Check /tmp/spire-build.log"
        exit 1
    fi
    echo "   ✓ Build complete"
else
    echo "   ❌ Build failed! Check /tmp/spire-build.log"
    tail -50 /tmp/spire-build.log
    exit 1
fi

# Copy binaries
echo ""
echo "📦 Copying binaries..."
mkdir -p "$BUILD_DIR/spire-binaries"

if [ -f "bin/spire-server" ]; then
    cp bin/spire-server "$BUILD_DIR/spire-binaries/"
    echo "   ✓ spire-server → build/spire-binaries/"
else
    echo "   ❌ spire-server not found in bin/"
    ls -la bin/ || true
    exit 1
fi

if [ -f "bin/spire-agent" ]; then
    cp bin/spire-agent "$BUILD_DIR/spire-binaries/"
    echo "   ✓ spire-agent → build/spire-binaries/"
else
    echo "   ❌ spire-agent not found in bin/"
    exit 1
fi

# Verify binaries
echo ""
echo "✅ Build verification:"
if [ -f "$BUILD_DIR/spire-binaries/spire-server" ]; then
    SERVER_VERSION=$("$BUILD_DIR/spire-binaries/spire-server" --version 2>&1 | head -1)
    echo "   Server: $SERVER_VERSION"
else
    echo "   ❌ spire-server not found!"
    exit 1
fi

if [ -f "$BUILD_DIR/spire-binaries/spire-agent" ]; then
    AGENT_VERSION=$("$BUILD_DIR/spire-binaries/spire-agent" --version 2>&1 | head -1)
    echo "   Agent:  $AGENT_VERSION"
else
    echo "   ❌ spire-agent not found!"
    exit 1
fi

# Record build info
cd "$PROJECT_ROOT"
echo "$SPIRE_VERSION" > .spire-version
cat > "$BUILD_DIR/BUILD_INFO.txt" << EOF
SPIRE Version: $SPIRE_VERSION
Built: $(date)
Platform: $(uname -s)/$(uname -m)
Go Version: $(go version)

AegisSovereignAI Modifications:
- Proto: SovereignAttestation APIs (4 proto files)
- Modules: Keylime, Policy, Unified Identity
- Plugins: Agent + Server + Composer (9 Go files)

Build artifacts:
- Server: build/spire-binaries/spire-server
- Agent:  build/spire-binaries/spire-agent
EOF

echo ""
echo "🎉 Custom SPIRE build complete!"
echo ""
echo "📁 Binaries available:"
echo "   Server: $BUILD_DIR/spire-binaries/spire-server"
echo "   Agent:  $BUILD_DIR/spire-binaries/spire-agent"
echo ""
echo "📋 Build info: $BUILD_DIR/BUILD_INFO.txt"
echo ""
echo "🚀 Next steps:"
echo "   1. Test: ./scripts/spire-test.sh"
echo "   2. Deploy: cp build/spire-binaries/* /usr/local/bin/"
echo ""
