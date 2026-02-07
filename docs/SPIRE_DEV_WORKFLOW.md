# SPIRE Development Workflow

This document explains how to develop new features for SPIRE overlay patches.

## Overview

The Aegis repository uses an **overlay system** to keep the repo clean while still allowing full SPIRE development when needed.

```
Normal State (Clean):
└── spire-overlay/ (patches only, ~50 files)

Development State (Temporary):
├── spire-overlay/ (patches)
└── build/spire-dev/ (full SPIRE fork, 17k files)
```

## Workflow

### 1. Setup Development Environment

Generate a temporary SPIRE fork with your patches applied:

```bash
./scripts/spire-dev-setup.sh
```

This creates:
- `build/spire-dev/spire/` - Full SPIRE repository
- Applied with all your overlay patches
- Ready for development with IDE support

### 2. Make Changes

Work in the development environment:

```bash
cd build/spire-dev/spire

# Make your changes with full IDE support
vim pkg/server/api/agent/v1/service.go

# Test your changes
make build
make test

# Commit your changes
git add -A
git commit -m "Add new attestation feature"
```

### 3. Extract Changes Back to Patches

After committing your changes:

```bash
cd $PROJECT_ROOT
./scripts/spire-dev-extract.sh
```

This:
- Regenerates all patch files
- Backs up old patches
- Updates `spire-overlay/` directory

### 4. Cleanup

Remove the temporary fork:

```bash
./scripts/spire-dev-cleanup.sh
```

Your repo is now clean again with only the updated patches!

### 5. Test and Commit

```bash
# Test the updated overlay
./scripts/spire-build.sh

# Verify binaries work
cd hybrid-cloud-poc
./test_control_plane.sh

# Commit the updated patches
git add spire-overlay/
git commit -m "feat: add new attestation endpoint"
```

## Best Practices

### ✅ DO

- Keep the dev environment temporary
- Extract and cleanup frequently
- Test after every extraction
- Commit patches to git

### ❌ DON'T

- Commit the `build/spire-dev/` directory to git
- Keep the dev environment for days
- Make changes directly to patch files (use dev environment instead)
- Forget to extract before cleanup

## Examples

### Adding a New Proto Field

```bash
# Setup
./scripts/spire-dev-setup.sh
cd build/spire-dev/spire

# Edit proto
vim proto/spire/api/types/sovereignattestation.proto

# Regenerate Go code
make proto-generate

# Test
make test

# Commit
git add -A
git commit -m "Add TPM quote field"

# Extract and cleanup
cd ../../..
./scripts/spire-dev-extract.sh
./scripts/spire-dev-cleanup.sh

# Test overlay
./scripts/spire-build.sh
```

### Updating SPIRE Version

```bash
# Update version in spire-dev-setup.sh
SPIRE_VERSION="v1.11.0" ./scripts/spire-dev-setup.sh

# If patches fail, fix conflicts manually
cd build/spire-dev/spire
# ... fix conflicts ...
git add -A && git commit

# Extract updated patches
cd ../../..
./scripts/spire-dev-extract.sh
./scripts/spire-dev-cleanup.sh
```

## Troubleshooting

### Patch doesn't apply

```bash
# Setup dev environment
./scripts/spire-dev-setup.sh

# If patch fails, fix manually:
cd build/spire-dev/spire
# Fix the conflicts
git add -A && git commit
cd ../../..
./scripts/spire-dev-extract.sh
```

### Lost uncommitted changes

```bash
# Check if dev environment still exists
ls build/spire-dev/spire

# If yes, extract now:
./scripts/spire-dev-extract.sh
```

### Need to work on multiple features

```bash
# Create separate dev environments
DEV_ENV_NAME=feature-1 ./scripts/spire-dev-setup.sh
DEV_ENV_NAME=feature-2 ./scripts/spire-dev-setup.sh

# Work in each separately, extract independently
```

## Repository States

### Clean State (Default)

```
.
├── spire-overlay/
│   ├── core-patches/
│   │   ├── server-api.patch (28k lines)
│   │   ├── server-endpoints.patch (13k lines)
│   │   └── feature-flags.patch
│   ├── proto-patches/
│   ├── plugins/
│   └── packages/
├── scripts/
│   ├── spire-build.sh          # Production builds
│   ├── spire-dev-setup.sh      # Dev environment
│   ├── spire-dev-extract.sh    # Extract changes
│   └── spire-dev-cleanup.sh    # Cleanup
└── build/                      # .gitignore'd
```

### Development State (Temporary)

```
.
├── spire-overlay/              # Your patches
├── scripts/                    # Scripts
└── build/
    ├── spire-binaries/         # Production build
    └── spire-dev/              # Development (temporary)
        └── spire/              # Full fork
```

## FAQ

**Q: Why not keep the fork permanently?**  
A: 17,315 files pollute the repo. Overlay keeps it clean.

**Q: Can I work directly in patch files?**  
A: Technically yes, but very error-prone. Use dev environment.

**Q: What if I forget to extract?**  
A: The cleanup script warns you and offers to extract first.

**Q: Is this needed for small patch edits?**  
A: No. For fixing line numbers, edit patches directly.
