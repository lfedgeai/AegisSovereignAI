#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Unified Identity — Single-Button Demo Runner
#
#  One command to: cleanup → build → start all services → run the demo.
#
#  Usage:
#    ./run-demo.sh              # Auto setup, interactive demo (~7 min)
#    ./run-demo.sh --auto       # Fully automatic — zero interaction, end to end
#    ./run-demo.sh --full       # Use full demo.sh (~20 min, all ZKP deep-dives)
#    ./run-demo.sh --skip-build # Skip build (reuse existing binaries)
#    ./run-demo.sh --help       # Show this help
#
#  Environment Variables:
#    CONTROL_PLANE_HOST         Override control plane host (default: 127.0.0.1)
#    AGENTS_HOST                Override agents host (default: 127.0.0.1)
#    ONPREM_HOST                Override on-prem host (default: 127.0.0.1)
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ── Parse args ───────────────────────────────────────────────────────────────
DEMO_SCRIPT="demo-speed.sh"
DEMO_ARGS=""
SKIP_BUILD=false

for arg in "$@"; do
    case "$arg" in
        --auto)
            DEMO_ARGS="--auto"
            ;;
        --full)
            DEMO_SCRIPT="demo.sh"
            ;;
        --speed)
            DEMO_SCRIPT="demo-speed.sh"
            ;;
        --skip-build)
            SKIP_BUILD=true
            ;;
        --help|-h)
            head -18 "$0" | tail -16 | sed 's/^#  \?//'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}" >&2
            echo "Use --help for usage info"
            exit 1
            ;;
    esac
done

# ── Helpers ──────────────────────────────────────────────────────────────────
step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  STEP $1: $2${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

elapsed() {
    local secs=$1
    printf '%dm %ds' $((secs / 60)) $((secs % 60))
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 1: Check & install prerequisites
# ══════════════════════════════════════════════════════════════════════════════
step 1 "Prerequisites — checking OS dependencies"

MISSING=0
check_dep() {
    if command -v "$1" &>/dev/null; then
        echo -e "    ${GREEN}✓${NC}  $2"
    else
        echo -e "    ${RED}✗${NC}  $2 ${DIM}(not found: $1)${NC}"
        MISSING=$((MISSING + 1))
    fi
}

check_dep go        "Go toolchain"
check_dep cargo     "Rust toolchain"
check_dep python3   "Python 3"
check_dep tpm2_getcap "TPM2 tools"

# Check for TPM device
if [ -e /dev/tpm0 ] || [ -e /dev/tpmrm0 ]; then
    echo -e "    ${GREEN}✓${NC}  Hardware TPM device"
else
    echo -e "    ${YELLOW}⚠${NC}  No /dev/tpm* found — TPM required for attestation"
fi

if [ "$MISSING" -gt 0 ]; then
    echo ""
    echo -e "    ${YELLOW}${BOLD}Installing missing dependencies...${NC}"
    if [ -x "${SCRIPT_DIR}/install_prerequisites.sh" ]; then
        "${SCRIPT_DIR}/install_prerequisites.sh"
        # Re-source environment in case Rust/Go were just installed
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        export PATH=$PATH:/usr/local/go/bin
        echo -e "    ${GREEN}✅  Prerequisites installed${NC}"
    else
        echo -e "    ${RED}❌  install_prerequisites.sh not found at ${SCRIPT_DIR}${NC}"
        exit 1
    fi
else
    echo -e "    ${GREEN}✅  All prerequisites satisfied${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 2: Cleanup previous state
# ══════════════════════════════════════════════════════════════════════════════
step 2 "Cleanup — stopping any running services"

python3 ci_test_runner.py --cleanup-only 2>&1 | tail -5 || true

echo -e "    ${GREEN}✅  Previous services stopped${NC}"

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 3: Build + Start all services + Run integration tests
# ══════════════════════════════════════════════════════════════════════════════
step 3 "Build & Start — building all components, starting services, running integration tests"

BUILD_START=$(date +%s)

CI_ARGS="--no-cleanup"
if [ "$SKIP_BUILD" = true ]; then
    CI_ARGS="$CI_ARGS -- --no-build"
    echo -e "    ${DIM}(skipping build — using existing binaries)${NC}"
fi

if ! python3 ci_test_runner.py $CI_ARGS; then
    echo ""
    echo -e "${RED}${BOLD}  ❌  Build/Integration test failed. Check logs above.${NC}"
    echo -e "${RED}      Fix the issue and re-run: ./run-demo.sh${NC}"
    exit 1
fi

BUILD_END=$(date +%s)
echo -e "    ${GREEN}✅  All services running, integration tests passed ($(elapsed $((BUILD_END - BUILD_START))))${NC}"

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 4: Run the demo
# ══════════════════════════════════════════════════════════════════════════════
step 4 "Demo — launching ${DEMO_SCRIPT}"
echo -e "    ${DIM}All services are running. Starting the live demo...${NC}"
echo ""

./${DEMO_SCRIPT} ${DEMO_ARGS}

echo ""
echo -e "${GREEN}${BOLD}  ══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✅  Demo complete. Services are still running.${NC}"
echo -e "${GREEN}${BOLD}  ══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${DIM}  To clean up:  python3 ci_test_runner.py --cleanup-only${NC}"
echo -e "${DIM}  To re-run demo without rebuild:  ./run-demo.sh --skip-build${NC}"
echo ""
