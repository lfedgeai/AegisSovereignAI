#!/bin/bash

# Copyright 2025 AegisSovereignAI Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =============================================================================
# Uninstall script — reverses install_prerequisites.sh
# =============================================================================
#
# Usage:
#   ./uninstall_prerequisites.sh              # uninstall locally
#   ./uninstall_prerequisites.sh 10.1.0.10    # uninstall on remote host
#
# Levels:
#   --safe     (default) Remove pip packages, Go tarball, Rust, build artifacts
#   --full     Also remove apt packages (tpm2-tools, swtpm, build-essential, etc.)
#
# WARNING: --full removes system packages that may be used by other software.
#          On machines with real TPM hardware, this can leave the TPM in an
#          inconsistent state until packages are reinstalled.
# =============================================================================

set -euo pipefail

HOST_IP="${1:-}"
LEVEL="${2:---safe}"
SSH_USER="${SSH_USER:-$USER}"

if [ -n "$HOST_IP" ]; then
    echo "Uninstalling on remote host: $HOST_IP"
    SSH_CMD="ssh ${SSH_USER}@${HOST_IP}"
else
    echo "Uninstalling on local system"
    SSH_CMD=""
fi

run_cmd() {
    if [ -n "$SSH_CMD" ]; then
        $SSH_CMD "$1"
    else
        eval "$1"
    fi
}

echo ""
echo "=========================================="
echo "Uninstalling Prerequisites (level: $LEVEL)"
echo "=========================================="

# ── 1. Python pip packages ───────────────────────────────────────────────────
echo ""
echo "--- Removing Python pip packages ---"
PIP_PKGS="spiffe cryptography grpcio grpcio-tools protobuf requests pre-commit"
# Try user-level first, then system-level (packages may be installed either way)
run_cmd "python3 -m pip uninstall -y $PIP_PKGS 2>/dev/null || true"
run_cmd "sudo python3 -m pip uninstall -y $PIP_PKGS 2>/dev/null || true"
echo "  ✓ pip packages removed"

# ── 2. Rust toolchain ────────────────────────────────────────────────────────
echo ""
echo "--- Removing Rust toolchain ---"
if run_cmd "which rustup" 2>/dev/null; then
    run_cmd "rustup self uninstall -y 2>/dev/null || true"
    echo "  ✓ Rust uninstalled via rustup"
else
    echo "  (Rust not installed, skipping)"
fi
# Clean up cargo dir even if rustup is gone
run_cmd "rm -rf \$HOME/.cargo \$HOME/.rustup 2>/dev/null || true"

# ── 3. Go toolchain (tarball install) ────────────────────────────────────────
echo ""
echo "--- Removing Go toolchain (tarball) ---"
if [ -d "/usr/local/go" ] || run_cmd "test -d /usr/local/go" 2>/dev/null; then
    run_cmd "sudo rm -rf /usr/local/go"
    echo "  ✓ /usr/local/go removed"
    echo "  NOTE: If Go was installed via apt, it is NOT removed (use --full for that)"
else
    echo "  (No /usr/local/go found, skipping)"
fi

# ── 4. Build artifacts ──────────────────────────────────────────────────────
echo ""
echo "--- Removing build artifacts ---"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
run_cmd "rm -rf ${PROJECT_DIR}/build 2>/dev/null || true"
run_cmd "rm -rf ${PROJECT_DIR}/rust-keylime/target 2>/dev/null || true"
run_cmd "rm -rf ${PROJECT_DIR}/enterprise-private-cloud/wasm-plugin/target 2>/dev/null || true"
run_cmd "rm -rf ${PROJECT_DIR}/mobile-sensor-microservice/zkp-prover-plonky2/target 2>/dev/null || true"
# Generated proto files
run_cmd "rm -rf ${PROJECT_DIR}/python-app-demo/generated 2>/dev/null || true"
# Temp/runtime files
run_cmd "rm -rf /tmp/spire-* /tmp/keylime* /tmp/mobile-sensor* /tmp/svid-dump 2>/dev/null || true"
echo "  ✓ build artifacts removed"

# ── SAFE level stops here ───────────────────────────────────────────────────
if [ "$LEVEL" = "--safe" ]; then
    echo ""
    echo "=========================================="
    echo "Safe uninstall complete"
    echo "=========================================="
    echo ""
    echo "Removed: pip packages, Rust, Go tarball, build artifacts"
    echo "Kept:    apt packages (tpm2-tools, swtpm, gcc, python3, libssl-dev)"
    echo ""
    echo "To reinstall: ./install_prerequisites.sh"
    echo "To also remove apt packages: $0 $HOST_IP --full"
    exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# FULL uninstall — also removes apt packages
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo "⚠  FULL uninstall — removing system packages"
echo ""

# ── 5. TPM packages ─────────────────────────────────────────────────────────
echo "--- Removing TPM2 packages ---"
echo "  WARNING: This may affect hardware TPM functionality until reinstalled"
run_cmd "sudo apt-get remove -y tpm2-tools tpm2-abrmd swtpm swtpm-tools 2>/dev/null || true"
# Don't remove libtss2 packages — they're often dependencies of other things
echo "  ✓ tpm2-tools, tpm2-abrmd, swtpm removed"

# ── 6. Build tools ──────────────────────────────────────────────────────────
echo ""
echo "--- Removing build tools ---"
run_cmd "sudo apt-get remove -y libclang-dev libclang-14-dev cmake 2>/dev/null || true"
# NOT removing build-essential, gcc, python3, libssl-dev — too dangerous
echo "  ✓ libclang-dev, cmake removed"
echo "  NOTE: build-essential, gcc, python3, libssl-dev are NOT removed (system dependencies)"

# ── 7. Go via apt ────────────────────────────────────────────────────────────
echo ""
echo "--- Removing Go (apt) ---"
run_cmd "sudo apt-get remove -y golang golang-go 2>/dev/null || true"
echo "  ✓ golang apt package removed"

# ── 8. Autoremove ────────────────────────────────────────────────────────────
echo ""
echo "--- Running apt autoremove ---"
run_cmd "sudo apt-get autoremove -y 2>/dev/null || true"

echo ""
echo "=========================================="
echo "Full uninstall complete"
echo "=========================================="
echo ""
echo "Removed: pip packages, Rust, Go, build artifacts, TPM tools, cmake, libclang"
echo "Kept:    build-essential, gcc, python3, libssl-dev (system dependencies)"
echo ""
echo "To reinstall everything: ./install_prerequisites.sh"
echo ""
