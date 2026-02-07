#!/bin/bash
set -e

# Cleanup temporary SPIRE development environment
# Removes build/spire-dev after extracting changes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEV_DIR="$PROJECT_ROOT/build/spire-dev"

echo "🧹 Cleaning up SPIRE development environment"
echo ""

if [ ! -d "$DEV_DIR" ]; then
    echo "ℹ️  No development environment to clean (already clean)"
    exit 0
fi

# Check for uncommitted changes
if [ -d "$DEV_DIR/spire" ]; then
    cd "$DEV_DIR/spire"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "⚠️  WARNING: You have uncommitted changes in the dev environment!"
        echo ""
        read -p "   Extract changes first? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$PROJECT_ROOT"
            ./scripts/spire-dev-extract.sh
            echo ""
            echo "✅ Changes extracted. Proceeding with cleanup..."
            echo ""
        else
            read -p "   Delete anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "❌ Cleanup cancelled"
                exit 1
            fi
        fi
    fi
fi

# Remove dev directory
echo "🗑️  Removing: $DEV_DIR"
rm -rf "$DEV_DIR"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Your repository is now clean with only the overlay patches."
echo "Run ./scripts/spire-dev-setup.sh when you need to develop again."
echo ""
