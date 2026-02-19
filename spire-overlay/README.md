# SPIRE Overlay System

This directory contains **only** the modifications AegisSovereignAI makes to upstream SPIRE.

**Why overlay?** We maintain 50 patch files instead of 17,315 fork files (99.7% reduction).

## Quick Start

### Production Build
```bash
./scripts/spire-build.sh          # Builds SPIRE v1.14.1 with Aegis patches
ls build/spire-binaries/          # Output: spire-server, spire-agent
```

### Development Workflow

**When you need to modify SPIRE code:**

```bash
# 1. Setup (creates temporary fork with IDE support)
./scripts/spire-dev-setup.sh

# 2. Develop
cd build/spire-dev/spire
# Edit files with full IDE/autocomplete support
vim pkg/server/api/agent/v1/service.go
make build && make test
git commit -am "Add TPM attestation feature"

# 3. Extract changes back to patches
cd ../../..
./scripts/spire-dev-extract.sh

# 4. Cleanup (removes temporary fork)
./scripts/spire-dev-cleanup.sh

# 5. Commit updated patches
git add spire-overlay/
git commit -m "feat: add TPM attestation"
```

**See [docs/SPIRE_DEV_WORKFLOW.md](../docs/SPIRE_DEV_WORKFLOW.md) for detailed guide.**

## Structure

```
spire-overlay/
├── proto-patches/          # Proto API extensions
│   └── files/
│       └── spire-api-sdk/
│           └── spire/api/
│               ├── server/agent/v1/agent.proto    # Attestation API
│               ├── server/svid/v1/svid.proto      # SVID extensions
│               └── types/
│                   └── sovereignattestation.proto  # Hardware attestation types
│
├── core-patches/           # SPIRE core modifications (11 patches)
│   ├── server-api.patch              # New attestation API endpoints
│   ├── server-endpoints.patch        # Sovereign attestation handlers
│   ├── feature-flags.patch           # Feature flag integration
│   ├── agent-core.patch              # Agent sovereign identity wiring
│   ├── agent-config.patch            # Agent config for sovereign endpoint
│   ├── agent-client.patch            # Agent gRPC client extensions
│   ├── agent-svid-rotator.patch      # SVID rotation sovereign hooks
│   ├── agent-svid-rotator-config.patch  # SVID rotator config extension
│   ├── agent-manager-config.patch    # Agent manager config extension
│   ├── agent-catalog.patch           # Agent catalog sovereign types
│   └── agent-trustbundle.patch       # Trust bundle sovereign extension
│
├── plugins/                # Aegis-specific plugins (NOT for upstream)
│   ├── server-keylime/          # Keylime remote attestation integration
│   ├── server-policy/           # Policy engine for access control
│   ├── server-unifiedidentity/  # Unified identity claims processing
│   ├── agent-nodeattestor-unifiedidentity/  # Agent-side attestation
│   └── server-credentialcomposer-unifiedidentity/  # Credential composition
│
├── catalog-patches/        # Catalog wiring for sovereign types (copied into SPIRE build)
│   ├── server-credentialcomposer-catalog.go  # Registers unified identity credential composer
│   └── agent-nodeattestor-catalog.go         # Registers unified identity node attestor
│
├── new-packages/           # Net-new Go packages (not patches — added wholesale)
│   ├── pkg/agent/tpmplugin/      # TPM attestation gateway (hardware SVID signing)
│   ├── pkg/agent/plugin/collector/ # Collector plugin type + sovereign implementation
│   ├── pkg/agent/catalog/        # Catalog entry for Collector plugin
│   ├── pkg/agent/util/           # CSR construction helper
│   └── pkg/server/credtemplate/  # AttestedClaims X.509 extension builder
│
├── common-packages/        # Shared utilities
│   ├── pluginconf/              # Plugin configuration helpers
│   └── tlspolicy/               # TLS policy enforcement
│
├── cache-packages/         # Custom caching
│   └── nodecache/               # Node cache implementation
│
└── patches.json            # Patch metadata
```

## What Goes Upstream vs Stays in Aegis

### ✅ For SPIRE Upstream
- **Proto extensions** (`proto-patches/`) - Optional fields, backward compatible
- **TPM DevID plugin** (`../spire-plugins/spire-tpm-devid-plugin/`) - Hardware attestation
- **Core patches** (subset) - API endpoints, feature flags

### 🔒 Stays in Aegis
- **Keylime integration** (`plugins/server-keylime/`) - Business logic
- **Policy engine** (`plugins/server-policy/`) - Aegis-specific access control
- **Unified identity** (`plugins/server-unifiedidentity/`) - Aegis-specific implementation

## How It Works

```
┌─────────────────────────────────────────────┐
│ scripts/spire-build.sh                      │
├─────────────────────────────────────────────┤
│ 1. Clone SPIRE v1.14.1 from upstream       │
│ 2. Apply proto-patches/                     │
│ 3. Apply core-patches/*.patch               │
│ 4. Copy plugins/ into pkg/server/plugin/    │
│ 5. Copy packages/ into pkg/                 │
│ 6. Build binaries → build/spire-binaries/   │
└─────────────────────────────────────────────┘
```

## Repository States

**Normal state (clean):**
```
AegisSovereignAI/
├── spire-overlay/      # 50 files (patches only)
└── build/              # gitignored
    └── spire-binaries/ # Built binaries
```

**Development state (temporary):**
```
AegisSovereignAI/
├── spire-overlay/      # Your patches
└── build/
    ├── spire-binaries/ # Built binaries
    └── spire-dev/      # Full SPIRE fork (temporary, gitignored)
```

## Testing Strategy

**Before submitting PRs to upstream:**

1. ✅ **Test overlay build** - `./scripts/spire-build.sh`
2. ✅ **Test on TPM hardware** - Linux machine with TPM 2.0
3. ✅ **Integration tests** - `cd hybrid-cloud-poc && ./test_integration.sh`
4. ✅ **Keylime attestation** - Verify end-to-end flow
5. ✅ **Create SPIRE fork** - Then extract specific patches for PRs

## Upstreaming Strategy

**DO NOT submit one massive PR!** Break into focused PRs:

1. **Proto extensions** - `sovereignattestation.proto` (easy to merge)
2. **TPM DevID plugin** - `spire-plugins/spire-tpm-devid-plugin/` (standalone)
3. **Server API** - Subset of `server-api.patch` (attestation endpoints)
4. **Feature flags** - `feature-flags.patch` (opt-in mechanism)

**Keep in Aegis:** Keylime, policy engine, unified identity (business logic)

## Version Management

```bash
# Current locked version
SPIRE_VERSION="v1.14.1"  # In scripts/spire-build.sh

# Don't update until upstream PRs are merged
# After PRs merge, update version and remove merged patches
```

## Maintenance Notes

- **Patches are large** - `server-api.patch` (28k lines), `server-endpoints.patch` (13k lines)
  - This is normal - they contain diff output, not raw code
  - They create entire new API modules for hardware attestation
  
- **Update workflow** - When SPIRE releases new version:
  1. Try `SPIRE_VERSION=v1.11.0 ./scripts/spire-build.sh`
  2. If patches fail, use dev workflow to regenerate
  3. Test thoroughly before committing updated patches

- **Backup safety** - `spire-dev-extract.sh` backs up old patches to `.backup-*/`

## Further Reading

- [SPIRE Development Workflow](../docs/SPIRE_DEV_WORKFLOW.md) - Detailed development guide
- [SPIRE Upstream Vision](../SPIRE_UPSTREAM_VISION.md) - What to upstream and why (if exists)
- [TPM DevID Plugin](../spire-plugins/spire-tpm-devid-plugin/) - Standalone TPM 2.0 attestor


