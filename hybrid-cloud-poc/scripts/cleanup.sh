#!/usr/bin/env bash

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

# Unified-Identity: Cleanup Script
# Stops all services and cleans up all data directories, logs, and temporary files
# Use this script to reset the environment after running tests or deployments

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If sourced from test script, use PROJECT_ROOT if set, otherwise assume we're in scripts/ and go up one level
if [ -n "${PROJECT_ROOT:-}" ]; then
    PROJECT_DIR="${PROJECT_ROOT}"
elif [ "$(basename "${SCRIPT_DIR}")" = "scripts" ]; then
    PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    PROJECT_DIR="${SCRIPT_DIR}"
fi
# All components are now consolidated in the root directory
PHASE1_DIR="${PROJECT_DIR}"
PHASE2_DIR="${PROJECT_DIR}"
PHASE3_DIR="${PROJECT_DIR}"
KEYLIME_DIR="${PROJECT_DIR}/keylime"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [ ! -t 1 ] || [ -n "${NO_COLOR:-}" ]; then
    GREEN=""
    RED=""
    YELLOW=""
    CYAN=""
    BOLD=""
    NC=""
fi

# Only show header when executed directly, not when sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Unified-Identity: Cleanup                                    ║"
    echo "║  Stopping all services and cleaning up data                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
fi

# Safe pkill wrapper: prevents pkill -f from killing ancestor shells.
# When invoked via bash -c "... pkill -f X ...", the bash -c process's cmdline
# contains "X" as part of the -c argument, so pkill matches and kills it (exit 143).
# This function uses pgrep + grep to exclude the current process tree.
_safe_pkill() {
    local signal=""
    local pattern=""
    # Parse arguments: support _safe_pkill [-9] "pattern"
    if [[ "$1" == -* ]]; then
        signal="$1"
        pattern="$2"
    else
        pattern="$1"
    fi
    # Strategy: pgrep -f matches ANY process with the pattern anywhere in its
    # cmdline. This includes `bash -c '... spire-server ...'`, sshd handlers,
    # and pgrep itself. We filter these out by checking the process's actual
    # binary name (comm): only kill if the comm is NOT a shell/utility.
    # Service daemons (spire-server, keylime_verifier, etc.) have their own
    # comm names, so this safely targets only actual service processes.
    local _skip_comms="^(bash|sh|dash|zsh|fish|sshd|ssh|pgrep|grep|xargs|cat|awk|sed|kill|test_|run-demo|ci_test)$"

    local pids
    pids=$(pgrep -f "$pattern" 2>/dev/null) || true
    if [ -z "$pids" ]; then
        return 0
    fi

    local kill_pids=""
    while read -r _p; do
        [ -z "$_p" ] && continue
        # Skip our own PID and parent
        [ "$_p" = "$$" ] && continue
        [ "$_p" = "$PPID" ] && continue
        [ "$_p" = "$BASHPID" ] && continue
        # Get the comm (actual binary name) of the process
        local _comm
        _comm=$(ps -o comm= -p "$_p" 2>/dev/null) || continue
        # Skip if it's a shell, SSH, or utility — these only have the pattern
        # because it appears in their command-line arguments, not because
        # they ARE the service we want to stop
        if echo "$_comm" | grep -qEi "$_skip_comms"; then
            continue
        fi
        kill_pids="${kill_pids} $_p"
    done <<< "$pids"

    if [ -n "${kill_pids}" ]; then
        echo $kill_pids | xargs -r kill ${signal} 2>/dev/null || true
    fi
}

# Function to clean up temporary files in /tmp (shared across all test scripts)
# This can be called independently or as part of full cleanup
cleanup_tmp_files() {
    # Clean up temporary SVID certificate files (from Python apps during renewal)
    find /tmp -maxdepth 1 -name "tmp*.pem" -type f 2>/dev/null | xargs rm -f 2>/dev/null || true
    # Clean up other temporary test files
    rm -f /tmp/remote_test_*.log 2>/dev/null || true
    rm -f /tmp/integration_test.log 2>/dev/null || true
    rm -f /tmp/mtls-client-app.log 2>/dev/null || true
    rm -f /tmp/mtls-server-app.log 2>/dev/null || true
    # Clean up Python cache files
    find /tmp -name "*.pyc" -type f 2>/dev/null | xargs rm -f 2>/dev/null || true
    find /tmp -name "__pycache__" -type d 2>/dev/null | xargs rm -rf 2>/dev/null || true
}

# Function to stop all existing instances and clean up all data
# If SKIP_HEADER is set, don't print the header message (for use in test scripts)
stop_all_instances_and_cleanup() {
    if [ -z "${SKIP_HEADER:-}" ]; then
        echo -e "${CYAN}Stopping all existing instances and cleaning up all data...${NC}"
        echo ""
    fi

    # Step 1: Stop all processes
    echo "  1. Stopping all processes..."

    # 1.1: Stop SPIRE processes
    echo "     Stopping SPIRE Server and Agent..."
    _safe_pkill "spire-server"
    _safe_pkill "spire-agent"

    # 1.2: Stop Keylime processes
    echo "     Stopping Keylime Verifier and Registrar..."
    _safe_pkill "keylime_verifier"
    _safe_pkill "keylime\.cmd\.verifier"
    _safe_pkill "keylime_registrar"
    _safe_pkill "keylime\.cmd\.registrar"
    _safe_pkill "python.*keylime"

    # 1.3: Stop rust-keylime Agent
    echo "     Stopping rust-keylime Agent..."
    _safe_pkill "keylime_agent"
    _safe_pkill "rust-keylime"
    _safe_pkill "target/release/keylime_agent"

    # 1.4: Stop TPM Plugin Server
    echo "     Stopping TPM Plugin Server..."
    _safe_pkill "tpm_plugin_server"

    # 1.5: Stop mobile location verification microservice
    echo "     Stopping Mobile Location Verification microservice..."
    _safe_pkill "mobile-sensor-microservice"
    _safe_pkill "mobile_sensor_service"
    _safe_pkill "mobile-sensor-microservice/service.py"
    _safe_pkill "service.py.*--port.*9050"
    _safe_pkill "service.py.*--host.*127.0.0.1"
    _safe_pkill "python3.*service.py.*--port"

    # 1.6: Stop TPM resource manager and any software TPM emulators
    _safe_pkill "tpm2-abrmd"
    _safe_pkill "swtpm"

    # 1.7: Free up ports
    if command -v lsof >/dev/null 2>&1; then
        echo "     Freeing up ports..."
        lsof -ti:8881,9002,8080,8081,8890,8891,9050 | xargs kill -9 >/dev/null 2>&1 || true
    fi

    # 1.8: Wait for processes to fully stop before cleaning data
    echo "     Waiting for processes to exit..."
    sleep 3

    # Force kill any remaining processes if they didn't exit gracefully
    if pgrep -f "spire-server|spire-agent|keylime|tpm_plugin|service.py.*--port" >/dev/null 2>&1; then
        echo "     Force killing remaining processes..."
        _safe_pkill -9 "spire-server|spire-agent|keylime|tpm_plugin|service.py.*--port"
        sleep 1
    fi


    # Step 2: Clean up all data directories and databases
    echo "  2. Cleaning up all data directories and databases..."

    # Clean up SPIRE data directories
    echo "     Removing SPIRE data directories..."
    sudo rm -rf /opt/spire/data 2>/dev/null || true
    sudo rm -rf /tmp/spire-server 2>/dev/null || true
    sudo rm -rf /tmp/spire-agent 2>/dev/null || true
    sudo rm -rf /tmp/spire-data 2>/dev/null || true

    # Clean up Keylime databases and persistent data
    echo "     Removing Keylime databases and persistent data..."
    if [ -n "${KEYLIME_DIR:-}" ] && [ -d "${KEYLIME_DIR}" ]; then
        rm -f "${KEYLIME_DIR}/verifier.db" 2>/dev/null || true
        rm -f "${KEYLIME_DIR}/verifier.sqlite" 2>/dev/null || true
        rm -f "${KEYLIME_DIR}/cv_data.sqlite" 2>/dev/null || true
        rm -f "${KEYLIME_DIR}"/*.db 2>/dev/null || true
        rm -f "${KEYLIME_DIR}"/*.sqlite 2>/dev/null || true
    fi
    # Clean up /tmp/keylime directory (contains registrar database)
    sudo rm -rf /tmp/keylime 2>/dev/null || true
    # Clean up any Keylime data in user home directory
    rm -rf "$HOME/.keylime" 2>/dev/null || true
    rm -rf "$HOME/.local/share/keylime" 2>/dev/null || true
    # Clean up any Keylime data in /var/lib/keylime (if accessible)
    sudo rm -rf /var/lib/keylime 2>/dev/null || true

    # Clean up TPM data
    echo "     Removing TPM data..."
    rm -rf /tmp/phase3-demo-tpm 2>/dev/null || true
    rm -rf "$HOME/.spire/data/agent/tpm-plugin" 2>/dev/null || true
    rm -rf "$HOME/.spire" 2>/dev/null || true
    sudo rm -rf /tmp/spire-data/tpm-plugin 2>/dev/null || true
    sudo rm -rf /tmp/tpm-plugin-* 2>/dev/null || true
    sudo rm -rf /tmp/rust-keylime-data 2>/dev/null || true
    # Clean up any TPM plugin state files
    rm -f /tmp/tpm-plugin*.pid 2>/dev/null || true
    rm -f /tmp/tpm-plugin*.log 2>/dev/null || true
    rm -f /tmp/tpm-plugin*.sock 2>/dev/null || true

    # Clean up mobile location verification microservice data
    echo "     Removing mobile location verification microservice data..."
    rm -rf /tmp/mobile-sensor-service 2>/dev/null || true
    rm -f /tmp/mobile-sensor-microservice.pid 2>/dev/null || true
    # Clean up SQLite database files
    rm -f /tmp/mobile-sensor-service/*.db 2>/dev/null || true
    rm -f /tmp/sensor_mapping.db 2>/dev/null || true

    # Clean up rust-keylime agent directory (after ensuring tmpfs is unmounted)
    echo "     Removing rust-keylime agent data directory..."
    # Make sure it's not mounted before removing
    if mountpoint -q "/tmp/keylime-agent/secure" 2>/dev/null; then
        echo -e "${YELLOW}     ⚠ Warning: /tmp/keylime-agent/secure still mounted, skipping directory removal${NC}"
    else
        sudo rm -rf /tmp/keylime-agent 2>/dev/null || true
    fi

    # Clean up SVID dump directory
    echo "     Removing SVID dump directory..."
    sudo rm -rf /tmp/svid-dump 2>/dev/null || true
    sudo rm -rf /tmp/agent-svid-dump 2>/dev/null || true

    # Clean up TLS certificates
    if [ -n "${KEYLIME_DIR:-}" ] && [ -d "${KEYLIME_DIR}" ]; then
        echo "     Removing TLS certificates..."
        rm -rf "${KEYLIME_DIR}/cv_ca" 2>/dev/null || true
        rm -rf "${KEYLIME_DIR}/reg_ca" 2>/dev/null || true
    fi

    # Step 3: Clean up all PID files
    echo "  3. Removing PID files..."
    rm -f /tmp/keylime-verifier.pid 2>/dev/null || true
    rm -f /tmp/keylime-registrar.pid 2>/dev/null || true
    rm -f /tmp/keylime-agent.pid 2>/dev/null || true
    rm -f /tmp/rust-keylime-agent.pid 2>/dev/null || true
    rm -f /tmp/spire-server.pid 2>/dev/null || true
    rm -f /tmp/spire-agent.pid 2>/dev/null || true
    rm -f /tmp/tpm-plugin-server.pid 2>/dev/null || true
    rm -f /tmp/mtls-server-app.pid 2>/dev/null || true
    rm -f /tmp/mobile-sensor-microservice.pid 2>/dev/null || true
    rm -f /tmp/rust-keylime-agent.pid 2>/dev/null || true

    # Step 4: Clean up all log files and temporary files (relevant to test_agents.sh only)
    echo "  4. Removing log files and temporary files..."
    # SPIRE log files
    rm -f /tmp/spire-server.log 2>/dev/null || true
    rm -f /tmp/spire-agent.log 2>/dev/null || true
    rm -f /tmp/spire-agent-test.log 2>/dev/null || true
    # Keylime log files
    rm -f /tmp/keylime-test.log 2>/dev/null || true
    rm -f /tmp/keylime-verifier.log 2>/dev/null || true
    rm -f /tmp/keylime-registrar.log 2>/dev/null || true
    rm -f /tmp/keylime-agent.log 2>/dev/null || true
    rm -f /tmp/rust-keylime-agent.log 2>/dev/null || true
    # TPM plugin log files
    rm -f /tmp/tpm-plugin-server.log 2>/dev/null || true
    # Mobile sensor microservice log files
    rm -f /tmp/mobile-sensor-microservice.log 2>/dev/null || true
    rm -f /tmp/mobile-sensor.log 2>/dev/null || true
    # mTLS server/client log files
    rm -f /tmp/mtls-server.log 2>/dev/null || true
    rm -f /tmp/mtls-server-app.log 2>/dev/null || true
    rm -f /tmp/mtls-client-app.log 2>/dev/null || true
    # Orchestrator/Remote execution log files
    rm -f /tmp/remote_test_*.log 2>/dev/null || true
    rm -f /tmp/wasm-build.log 2>/dev/null || true
    # Phase/workflow log files
    rm -f /tmp/bundle.pem 2>/dev/null || true
    rm -f /tmp/spire-bundle.pem 2>/dev/null || true
    rm -f /tmp/phase3_complete_workflow_logs.txt 2>/dev/null || true
    rm -f /tmp/phase3_*.log 2>/dev/null || true
    rm -f /tmp/test_phase3_*.log 2>/dev/null || true
    rm -f /tmp/workflow_visualization.html 2>/dev/null || true
    # Old backup files for relevant logs only
    rm -f /tmp/spire-*.log.old 2>/dev/null || true
    rm -f /tmp/keylime-*.log.old 2>/dev/null || true
    rm -f /tmp/tpm-plugin-*.log.old 2>/dev/null || true
    rm -f /tmp/mobile-sensor-*.log.old 2>/dev/null || true
    rm -f /tmp/phase3_*.log.old 2>/dev/null || true
    # Temporary config files (relevant to test_agents.sh)
    rm -f /tmp/keylime-agent-*.conf 2>/dev/null || true
    rm -f /tmp/*.conf.tmp 2>/dev/null || true
    # Python cache and temporary files (relevant to test_agents.sh components)
    find /tmp -name "*.pyc" -type f 2>/dev/null | xargs rm -f 2>/dev/null || true
    find /tmp -name "__pycache__" -type d 2>/dev/null | xargs rm -rf 2>/dev/null || true
    find /tmp -name "*.tmp" -type f 2>/dev/null | grep -E "(keylime|spire|tpm|mobile)" | xargs rm -f 2>/dev/null || true

    # Call shared /tmp cleanup function
    cleanup_tmp_files

    # Clean up unified_identity test log directories
    echo "     Removing old unified_identity test logs..."
    if [ -n "${LOG_DIR:-}" ]; then
        # Protect the currently active test directory if it's within /tmp
        local CURRENT_DIR_NAME=$(basename "${LOG_DIR}")
        find /tmp -maxdepth 1 -name "unified_identity_test_*" ! -name "${CURRENT_DIR_NAME}" -type d -exec rm -rf {} + 2>/dev/null || true
    else
        rm -rf /tmp/unified_identity_test_* 2>/dev/null || true
    fi

    # Step 5: Clean up sockets
    echo "  5. Removing socket files..."
    rm -f /tmp/spire-server/private/api.sock 2>/dev/null || true
    rm -f /tmp/spire-agent/public/api.sock 2>/dev/null || true
    rm -f /var/run/keylime/keylime-agent-certify.sock 2>/dev/null || true
    rm -f "$HOME/.keylime/run/keylime-agent-certify.sock" 2>/dev/null || true
    rm -f /tmp/keylime-agent.sock 2>/dev/null || true
    rm -f /tmp/spire-data/tpm-plugin/tpm-plugin.sock 2>/dev/null || true
    rm -f /tmp/mobile-sensor.sock 2>/dev/null || true
    # Clean up any other socket files
    find /tmp -name "*.sock" -type s 2>/dev/null | grep -E "(keylime|spire|tpm)" | xargs rm -f 2>/dev/null || true
    rm -rf /tmp/spire-server 2>/dev/null || true
    rm -rf /tmp/spire-agent 2>/dev/null || true

    # Step 6: Recreate clean data directories (unless skipped)
    if [ "${SKIP_RECREATE:-false}" = "true" ]; then
        echo "  6. Skipping directory recreation as requested..."
        return 0
    fi

    echo "  6. Creating clean data directories..."
    sudo mkdir -p /opt/spire/data/server /opt/spire/data/agent 2>/dev/null || true
    sudo chown -R "$(whoami):$(whoami)" /opt/spire/data 2>/dev/null || true
    mkdir -p /tmp/spire-server/private 2>/dev/null || true
    mkdir -p /tmp/spire-agent/public 2>/dev/null || true
    mkdir -p /tmp/spire-data/server /tmp/spire-data/agent 2>/dev/null || true
    mkdir -p /tmp/rust-keylime-data 2>/dev/null || true
    mkdir -p ~/.keylime/run 2>/dev/null || true

    # Ensure keylime-agent directory is clean and ready (but don't mount tmpfs yet)
    mkdir -p /tmp/keylime-agent 2>/dev/null || true
    # Remove secure subdirectory if it exists (will be recreated and mounted by agent)
    if [ -d "/tmp/keylime-agent/secure" ] && ! mountpoint -q "/tmp/keylime-agent/secure" 2>/dev/null; then
        rm -rf /tmp/keylime-agent/secure 2>/dev/null || true
    fi

    # Final verification
    echo ""
    if ! pgrep -f "spire-server|spire-agent|keylime|tpm_plugin|service.py.*--port" >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ All existing instances stopped and all data cleaned up${NC}"
        return 0
    else
        echo -e "${YELLOW}  ⚠ Some processes may still be running:${NC}"
        pgrep -f "spire-server|spire-agent|keylime|tpm_plugin|service.py.*--port" || true
        return 1
    fi
}

# Usage helper
show_usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h, --help    Show this help message.

This script stops all Unified-Identity services and cleans up:
  - All running processes (SPIRE Server/Agent, Keylime Verifier/Registrar/Agent, TPM Plugin)
  - All data directories and databases
  - All log files and PID files
  - All socket files
  - TPM state (if accessible)
  - tmpfs mounts

After cleanup, clean data directories are recreated for the next run (unless --skip-recreate is used).

Options:
  -h, --help           Show this help message.
  --skip-recreate     Cleanup everything but don't recreate data directories.
  $0              # Run full cleanup
  $0 --help       # Show this help message
EOF
}

# Check if script is being sourced or executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly - parse arguments and run cleanup
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            --skip-recreate)
                export SKIP_RECREATE=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done

    # Run cleanup
    stop_all_instances_and_cleanup

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Cleanup Complete                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "All services have been stopped and data has been cleaned up."
    echo "You can now run setup.sh and test scripts again."
    echo ""
fi
# If script is sourced, functions are available but cleanup doesn't run automatically
