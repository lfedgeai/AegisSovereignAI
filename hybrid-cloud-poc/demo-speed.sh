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

# ═══════════════════════════════════════════════════════════════════════════════
#  Unified Identity — SPEED DEMO (~7 min)
#  Cuts: ZKP Parts 1 (recap), 2 (hash), 5 (comparison), Design Properties
#  Keeps: Infrastructure → SVID → mTLS → Circuit → Tamper → TEE → Closing
#
#  Usage:
#    ./demo-speed.sh              # interactive
#    ./demo-speed.sh --auto       # auto-advance (5s)
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'

PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
DUMP_DIR="/tmp/svid-dump"
SPIRE_AGENT_BIN="${PROJ_DIR}/../build/spire-binaries/spire-agent"
BUNDLE_PEM="/tmp/bundle.pem"
ENVOY_CERT="${HOME}/.mtls-demo/envoy-cert.pem"
ONPREM_HOST="${ONPREM_HOST:-127.0.0.1}"

AUTO_MODE=false
[[ "${1:-}" == "--auto" ]] && AUTO_MODE=true

# ── Helpers ──────────────────────────────────────────────────────────────────
banner() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

sub_banner() {
    echo -e "\n${YELLOW}── $1 ──${NC}\n"
}

pass() { echo -e "    ${GREEN}✅  $1${NC}"; }
fail() { echo -e "    ${RED}❌  $1${NC}"; }
info() { echo -e "    ${DIM}ℹ   $1${NC}"; }
warn() { echo -e "    ${YELLOW}⚠   $1${NC}"; }

pause_for_presenter() {
    echo ""
    if [ "$AUTO_MODE" = true ]; then
        echo -e "    ${DIM}[auto-advancing in 5s...]${NC}"
        sleep 5
    else
        echo -e "    ${DIM}[Press Enter to continue...]${NC}"
        read -r
    fi
    echo ""
}

# ── Ensure SVID dump exists (with retries for fresh restart) ─────────────────
ensure_svid_dump() {
    if [ -f "${DUMP_DIR}/attested_claims.json" ]; then
        if [ -f "${DUMP_DIR}/svid.pem" ]; then
            if openssl x509 -in "${DUMP_DIR}/svid.pem" -checkend 60 >/dev/null 2>&1; then
                return 0
            fi
            echo -e "    ${DIM}Existing SVID is expired or expiring soon — refreshing SVID dump...${NC}"
            warn "Stale SVID dump detected. This often happens when a previous --no-cleanup run left /tmp/svid-dump behind."
        else
            echo -e "    ${DIM}Existing SVID dump is incomplete — refreshing...${NC}"
            warn "Incomplete /tmp/svid-dump found. Refreshing the SVID dump now."
        fi
        rm -rf "${DUMP_DIR}"
    fi

    local attempt=0
    while [ ! -f "${DUMP_DIR}/attested_claims.json" ] && [ $attempt -lt 3 ]; do
        attempt=$((attempt + 1))
        [ $attempt -gt 1 ] && echo -e "    ${DIM}Waiting for SVID (attempt ${attempt}/3)...${NC}" && sleep 3
        python3 "${PROJ_DIR}/python-app-demo/fetch-sovereign-svid-grpc.py" >/dev/null 2>&1 || true
    done
    if [ ! -f "${DUMP_DIR}/attested_claims.json" ]; then
        warn "Could not fetch SVID — is SPIRE agent running?"
    fi
}

# ── Source functions from full demo (skip its main execution block) ──────────
# Extract all function definitions but not the main block
eval "$(awk '/^(act1_infrastructure|act2_1_agent|act2_2_workload|act2_3_envoy)\(\)/{found=1} found{print} found && /^}/{found=0}' "${PROJ_DIR}/demo.sh")"


# ═════════════════════════════════════════════════════════════════════════════
#  Title
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                               ║${NC}"
echo -e "${CYAN}║   ${BOLD}${GREEN}Unified Identity — Speed Demo${NC}${CYAN}                              ║${NC}"
echo -e "${CYAN}║   ${DIM}Agentic and Deterministic AI: HW/Silicon-Rooted Trust${NC}${CYAN}      ║${NC}"
echo -e "${CYAN}║                                                               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DIM}    Speed version: 8 slides (~7 min)${NC}"
echo -e "${DIM}    Mode: $([ "$AUTO_MODE" = true ] && echo "auto-advance (5s)" || echo "interactive (press Enter)")${NC}"

pause_for_presenter


# ═════════════════════════════════════════════════════════════════════════════
#  Slide 1: Infrastructure
# ═════════════════════════════════════════════════════════════════════════════
act1_infrastructure


# ═════════════════════════════════════════════════════════════════════════════
#  Slide 2: Agent SVID
# ═════════════════════════════════════════════════════════════════════════════
act2_1_agent


# ═════════════════════════════════════════════════════════════════════════════
#  Slide 3: mTLS
# ═════════════════════════════════════════════════════════════════════════════
act2_3_envoy


# ═════════════════════════════════════════════════════════════════════════════
#  Slides 4-5: ZKP Circuit + Tamper Attack (core only)
# ═════════════════════════════════════════════════════════════════════════════
act3_speed() {
    banner "ZKP Deep Dive — Circuit Verification + Attack Demo"

    ensure_svid_dump

    ZKP_PROVER="${PROJ_DIR}/mobile-sensor-microservice/zkp-prover-plonky2/target/release/zkp-prover"

    # ── Circuit verification (the core proof) ────────────────────────────
    sub_banner "ZKP Circuit Verification (Plonky2)"

    echo -e "    ${BOLD}Fetching proof from Keylime verifier receipt store...${NC}"

    PROOF_B64=$(python3 -c "
import json, ssl, urllib.request, sys, re
d = json.load(open('${DUMP_DIR}/attested_claims.json'))
lb = d.get('lah-bundle', d)
gp = lb.get('geolocation-payload', {})
if isinstance(gp, str):
    try: gp = json.loads(gp)
    except: gp = {}
uri = gp.get('zkp-proof-uri', '')
uri = re.sub(r'https://[^:/]+:', 'https://127.0.0.1:', uri)
try:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
    resp = urllib.request.urlopen(uri, context=ctx, timeout=5)
    receipt = json.loads(resp.read())
    print(receipt['results']['sovereignty_receipt'])
except Exception as e:
    print('', end='')
" 2>/dev/null) || PROOF_B64=""

    if [ -z "$PROOF_B64" ]; then
        warn "Could not extract ZKP proof — check attested_claims.json"
        pause_for_presenter
        return
    fi

    echo -e "    ${GREEN}✅  Proof retrieved (${#PROOF_B64} chars, base64-encoded)${NC}"
    echo ""

    if [ -x "$ZKP_PROVER" ]; then
        echo -e "    ${BOLD}Running Plonky2 verifier (verify-only mode):${NC}"
        echo -e "    ${DIM}zkp-prover --verify-only --proof=<proof>${NC}"
        echo ""

        VERIFY_OUT=$("$ZKP_PROVER" --verify-only --proof="$PROOF_B64" 2>&1) || true
        VERIFY_INPUTS=$(echo "$VERIFY_OUT" | grep -i "Public inputs" || true)
        VERIFY_RESULT=$(echo "$VERIFY_OUT" | grep -i "Proof VALID" || true)

        if [[ -n "$VERIFY_INPUTS" ]]; then
            CLAT=$(echo "$VERIFY_INPUTS" | grep -oP 'center_lat=\K[0-9]+')
            CLON=$(echo "$VERIFY_INPUTS" | grep -oP 'center_lon=\K[0-9]+')
            RADIUS=$(echo "$VERIFY_INPUTS" | grep -oP 'radius=\K[0-9]+')
            IDHASH=$(echo "$VERIFY_INPUTS" | grep -oP 'idhash=\K[0-9]+')

            echo -e "    ${BOLD}${CYAN}Public inputs (extracted from proof):${NC}"
            echo -e "      ${CYAN}center_lat${NC}  = ${GREEN}${CLAT}${NC}  ${DIM}(geofence policy)${NC}"
            echo -e "      ${CYAN}center_lon${NC}  = ${GREEN}${CLON}${NC}  ${DIM}(geofence policy)${NC}"
            echo -e "      ${CYAN}radius${NC}      = ${GREEN}${RADIUS}${NC}  ${DIM}(geofence policy)${NC}"
            echo -e "      ${CYAN}idhash${NC}      = ${GREEN}${IDHASH}${NC}  ${DIM}← SHA-256(TPM AK) — binds proof to THIS device${NC}"
            echo ""
            echo -e "    ${BOLD}${RED}Private inputs (NEVER revealed):${NC}"
            echo -e "      device-lat    = ${RED}██████████${NC}  ← hidden in proof"
            echo -e "      device-lon    = ${RED}██████████${NC}  ← hidden in proof"
            echo ""
            echo -e "    ${DIM}The verifier confirmed the claim WITHOUT learning the GPS coordinates.${NC}"
            echo -e "    ${DIM}This is the core ZKP value: ${BOLD}verify without knowing.${NC}"
        fi

        if [[ -n "$VERIFY_RESULT" ]]; then
            echo ""
            pass "CIRCUIT VALID — Plonky2 zero-knowledge proof verified"
        else
            fail "CIRCUIT INVALID"
        fi

        pause_for_presenter

        # ── Tamper attack ─────────────────────────────────────────────
        sub_banner "Attack — Tamper the Device Identity"

        echo -e "    ${DIM}Scenario: Attacker changes the idhash to claim a DIFFERENT TPM produced this proof${NC}"
        echo ""
        echo -e "    ${BOLD}Original idhash (from proof):${NC}  ${GREEN}${IDHASH}${NC}"
        echo -e "    ${BOLD}Tampered idhash (attacker):${NC}    ${RED}999999999${NC}"
        echo ""

        TAMPER_OUT=$("$ZKP_PROVER" --verify --proof="$PROOF_B64" \
            --clat="$CLAT" --clon="$CLON" --radius="$RADIUS" --idhash=999999999 2>&1) || true

        if echo "$TAMPER_OUT" | grep -qi "INVALID\|mismatch"; then
            fail "Proof INVALID: public inputs mismatch"
            echo ""
            echo -e "    ${BOLD}Why it failed:${NC}"
            echo -e "      The proof was generated with idhash = ${GREEN}${IDHASH}${NC} (SHA-256 of TPM AK pub)"
            echo -e "      The attacker supplied idhash = ${RED}999999999${NC}"
            echo -e "      The circuit rejects — the hash is part of the proof statement"
            echo ""
            echo -e "    ${BOLD}This means:${NC}"
            echo -e "      • Proof is bound to a SPECIFIC TPM via SHA-256(AK pub)"
            echo -e "      • You cannot transplant a valid proof to a different device"
        else
            pass "Tamper result: ${TAMPER_OUT}"
        fi

        pause_for_presenter
    else
        warn "zkp-prover binary not found at ${ZKP_PROVER}"
        pause_for_presenter
    fi
}
act3_speed


# ═════════════════════════════════════════════════════════════════════════════
#  Slide 6: ZKP + TEE Comparison (Part 6 from full demo)
# ═════════════════════════════════════════════════════════════════════════════
tee_comparison() {
    sub_banner "Part 6: ZKP + TEE — Complementary, Not Competing"

    echo -e "    ${BOLD}${CYAN}Each layer covers the other's blind spots:${NC}"
    echo ""
    echo -e "    ${BOLD}Threat                           ZKP alone    TEE alone    ZKP inside TEE${NC}"
    echo -e "    ${BOLD}─────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${GREEN}Verifier learns GPS${NC}              ${GREEN}✅ hidden${NC}    ${RED}❌ output${NC}    ${GREEN}✅ hidden${NC}"
    echo -e "    ${GREEN}Kernel 0-day reads GPS${NC}           ${RED}❌ ptrace${NC}    ${GREEN}✅ encrypted${NC} ${GREEN}✅ both protect${NC}"
    echo -e "    ${GREEN}TEE side-channel leaks data${NC}      n/a          ${RED}❌ Spectre${NC}   ${GREEN}✅ proof only${NC}"
    echo -e "    ${GREEN}Fake GPS from compromised OS${NC}     ${RED}❌${NC}           ${YELLOW}⚠ ecalls*${NC}   ${YELLOW}⚠ ecalls*${NC}"
    echo -e "    ${DIM}    * Mitigated by SR-IOV (DMA-isolated sensor) + signed location from GPS hardware${NC}"

    echo ""
    echo -e "    ${BOLD}${CYAN}The TEE integrity tradeoff:${NC}"
    echo -e "    ${DIM}  Co-located TEEs (TDX/SEV) disable ASLR for consistent launch measurement${NC}"
    echo -e "    ${BOLD}  TEE buys confidentiality by trading away a runtime integrity defense${NC}"

    echo ""
    echo -e "    ${BOLD}Where to run the ZKP prover:${NC}"
    echo -e "    ${DIM}Option 1:${NC}  Userspace sidecar      ${DIM}(today's POC)${NC}"
    echo -e "    ${DIM}Option 2:${NC}  TDX/SEV confidential VM  ${DIM}(confidentiality ✅ but ASLR ❌)${NC}"
    echo -e "    ${GREEN}${BOLD}Option 3:${NC}${GREEN}  Management processor (HPE iLO 7 / Dell iDRAC)    ${BOLD}← Strongest (ASLR preserved)${NC}"
    echo ""
    echo -e "    ${BOLD}Confidentiality by physics. Integrity without compromise.${NC}"

    pause_for_presenter
}
tee_comparison


# ═════════════════════════════════════════════════════════════════════════════
#  Slide 7: Closing
# ═════════════════════════════════════════════════════════════════════════════
banner "Summary: Unified Identity — Defence in Depth"

echo -e "    ${GREEN}${BOLD}WHO${NC}   → SPIFFE ID signed by SPIRE CA             ${DIM}(cert forgery ✘)${NC}"
echo -e "    ${GREEN}${BOLD}WHERE${NC} → ZKP proof sealed by TPM                  ${DIM}(GPS spoofing ✘)${NC}"
echo -e "    ${GREEN}${BOLD}WHAT${NC}  → Agent binary digest measured by Keylime   ${DIM}(tampering ✘)${NC}"
echo ""
echo -e "    ${BOLD}You cannot peel away any layer without invalidating the identity.${NC}"
echo ""
echo -e "    ${BOLD}${CYAN}Why this architecture, not just TEE?${NC}"
echo -e "    ${DIM}TEE solves confidentiality${NC}  — encrypts memory so the OS can't read it"
echo -e "    ${DIM}TEE weakens integrity${NC}      — disables ASLR for consistent attestation quotes"
echo -e "    ${DIM}ZKP solves verifiability${NC}   — mathematical proof, not \"trust the enclave\""
echo ""
echo -e "    ${BOLD}${GREEN}A stolen server gets no identity. It's cryptographically bricked.${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${GREEN}${BOLD}    Demo complete.${NC}"
echo ""
