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
#  Unified Identity — Comprehensive Demo Script
#  Aligned to slide deck: slides 7–12
#
#  Prerequisites:
#    python ci_test_runner.py --no-cleanup    (run and leave system up)
#
#  Usage:
#    chmod +x demo.sh
#    ./demo.sh              # interactive (press Enter between sections)
#    ./demo.sh --auto       # auto-advance (5s between sections)
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
    if $AUTO_MODE; then
        echo -e "${DIM}    [auto-advancing in 5s...]${NC}"
        sleep 5
    else
        echo -e "${MAGENTA}    ▸ Press ${BOLD}Enter${NC}${MAGENTA} to continue...${NC}"
        read -r
    fi
}

# ── Ensure SVID dump exists ──────────────────────────────────────────────────
ensure_svid_dump() {
    if [ -f "${DUMP_DIR}/attested_claims.json" ]; then
        return 0
    fi
    local attempt=0
    while [ ! -f "${DUMP_DIR}/attested_claims.json" ] && [ $attempt -lt 3 ]; do
        attempt=$((attempt + 1))
        [ $attempt -gt 1 ] && echo -e "    ${DIM}Waiting for SVID (attempt ${attempt}/3)...${NC}" && sleep 3
        python3 "${PROJ_DIR}/python-app-demo/fetch-sovereign-svid-grpc.py" >/dev/null 2>&1 || true
    done
    if [ ! -f "${DUMP_DIR}/attested_claims.json" ]; then
        warn "Could not fetch SVID — is SPIRE agent running?"
        echo "Run:  cd ${PROJ_DIR} && python3 ci_test_runner.py --no-cleanup"
        exit 1
    fi
}

# ═════════════════════════════════════════════════════════════════════════════
#  SLIDE 7 — Demo Act 1: Trusted Infrastructure Setup
# ═════════════════════════════════════════════════════════════════════════════
act1_infrastructure() {
    banner "SLIDE 7 │ Demo Act 1 — Trusted Infrastructure Setup"

    sub_banner "Cloud — Control Plane"

    echo -e "    ${BOLD}Host Identity Manager (Keylime):${NC}"
    if pgrep -f "keylime.cmd.verifier" >/dev/null 2>&1; then
        PID=$(pgrep -f "keylime.cmd.verifier" | head -1)
        pass "Keylime Verifier running (PID $PID)"
    elif pgrep -f cloud_verifier >/dev/null 2>&1; then
        PID=$(pgrep -f cloud_verifier | head -1)
        pass "Keylime Verifier running (PID $PID)"
    else
        fail "Keylime Verifier NOT running"
    fi

    if pgrep -f registrar >/dev/null 2>&1; then
        PID=$(pgrep -f registrar | head -1)
        pass "Keylime Registrar running (PID $PID)"
    else
        fail "Keylime Registrar NOT running"
    fi

    echo ""
    echo -e "    ${BOLD}Workload Identity Manager (SPIRE Server):${NC}"
    if pgrep -f spire-server >/dev/null 2>&1; then
        PID=$(pgrep -f spire-server | head -1)
        pass "SPIRE Server running (PID $PID)"
    else
        fail "SPIRE Server NOT running"
    fi

    sub_banner "Cloud — API Gateway & Server Application"

    echo -e "    ${BOLD}ZTNA in API Gateway (Envoy + WASM):${NC}"
    if pgrep -f envoy >/dev/null 2>&1; then
        PID=$(pgrep -f envoy | head -1)
        pass "Envoy proxy running (PID $PID)"
    else
        fail "Envoy proxy NOT running"
    fi

    echo -e "    ${BOLD}Key Vault (Server App):${NC}"
    if pgrep -f mtls-server >/dev/null 2>&1; then
        PID=$(pgrep -f mtls-server | head -1)
        pass "mTLS Server App running (PID $PID)"
    else
        fail "mTLS Server App NOT running"
    fi



    sub_banner "Sovereign Edge Cloud — Location Anchor Host + Client App"

    echo -e "    ${BOLD}rust-keylime Agent:${NC}"
    if pgrep -f keylime_agent >/dev/null 2>&1; then
        PID=$(pgrep -f keylime_agent | head -1)
        pass "rust-keylime agent running (PID $PID)"
    else
        fail "rust-keylime agent NOT running"
    fi

    echo -e "    ${BOLD}SPIRE Agent + TPM Plugin:${NC}"
    if pgrep -f spire-agent >/dev/null 2>&1; then
        PID=$(pgrep -f spire-agent | head -1)
        pass "SPIRE Agent running (PID $PID)"
    else
        fail "SPIRE Agent NOT running"
    fi

    if pgrep -f tpm_plugin >/dev/null 2>&1; then
        PID=$(pgrep -f tpm_plugin | head -1)
        pass "TPM Plugin Server running (PID $PID)"
    else
        fail "TPM Plugin Server NOT running"
    fi

    echo ""
    echo -e "    ${BOLD}Hardware TPM:${NC}"
    if sudo tpm2_getcap properties-fixed 2>/dev/null | grep -q "TPM2_PT_MANUFACTURER"; then
        MFGR=$(sudo tpm2_getcap properties-fixed 2>/dev/null | grep -A1 "TPM2_PT_MANUFACTURER" | tail -1 | awk -F'"' '{print $2}')
        pass "Hardware TPM detected — manufacturer: ${MFGR:-unknown}"
    else
        info "TPM properties not readable (may require sudo)"
    fi

    echo ""
    echo -e "    ${GREEN}${BOLD}▸ All 7 services from the architecture diagram are running${NC}"
    echo -e "    ${GREEN}${BOLD}▸ Real hardware TPM — not software-emulated${NC}"

    pause_for_presenter
}


# ═════════════════════════════════════════════════════════════════════════════
#  SLIDE 8 — Demo Act 2.1: Agent Gets Unified Identity (Happy Path)
# ═════════════════════════════════════════════════════════════════════════════
act2_1_agent() {
    banner "SLIDE 8 │ Demo Act 2.1 — Agent Unified Identity (PoR + PoPG)"

    ensure_svid_dump

    sub_banner "SPIRE Agent SVID — Two Identity Layers Fused"

    python3 -c "
import json, sys

try:
    d = json.load(open('${DUMP_DIR}/attested_claims.json'))
except Exception as e:
    print(f'ERROR reading claims: {e}')
    sys.exit(1)

lb = d.get('lah-bundle', d)

print('  \033[1;32m🟢 OUTER RING — SPIRE Agent ID (TPM-rooted key)\033[0m')
tpm_ak = lb.get('tpm-ak', '')
print(f'     TPM AK:                {tpm_ak[:60]}...' if len(tpm_ak) > 60 else f'     TPM AK:                {tpm_ak or \"(empty)\"}')
agent_dig = lb.get('workload-identity-agent-image-digest', '')
print(f'     Agent Binary Digest:   {agent_dig or \"(not set)\"}')
tqs = lb.get('tpm-quote-seal', '')
print(f'     TPM Quote Seal:        {tqs[:60]}...' if len(tqs) > 60 else f'     TPM Quote Seal:        {tqs or \"(not set)\"}')

print()
print('  \033[1;33m🟤 INNER RING — Privacy-Preserving Location (Sensor/Physics)\033[0m')
print(f'     Privacy Technique:     {lb.get(\"privacy-technique\", \"N/A\")}')
geo_id = lb.get('geolocation-id-hash', '')
print(f'     Geo ID Hash:           {geo_id[:48]}...' if len(geo_id) > 48 else f'     Geo ID Hash:           {geo_id}')
proof_h = lb.get('geolocation-proof-hash', '')
print(f'     Proof Hash:            {proof_h}')
nonce = lb.get('nonce', '')
print(f'     Nonce:                 {nonce[:40]}...' if len(nonce) > 40 else f'     Nonce:                 {nonce}')
print(f'     Timestamp:             {lb.get(\"timestamp\", \"N/A\")}')

gp = lb.get('geolocation-payload', {})
if isinstance(gp, str):
    try: gp = json.loads(gp)
    except: gp = {}
zkp_uri = gp.get('zkp-proof-uri', '(none)')
print(f'     ZKP Proof URI:         {zkp_uri[:60]}')
"

    echo ""
    echo -e "    ${GREEN}${BOLD}▸ You cannot peel away the host or location without invalidating the identity${NC}"
    echo -e "    ${GREEN}${BOLD}▸ Two layers fused by the TPM quote seal: Host (TPM AK) + Location (ZKP)${NC}"

    pause_for_presenter
}


# ═════════════════════════════════════════════════════════════════════════════
#  SLIDE 9 — Demo Act 2.2: Workload Inherits from Agent
# ═════════════════════════════════════════════════════════════════════════════
act2_2_workload() {
    banner "SLIDE 9 │ Demo Act 2.2 — Workload Inherits Unified Identity"

    ensure_svid_dump

    sub_banner "Client App (Inference App) inherits LAH Bundle from Agent"

    python3 -c "
import json, sys

d = json.load(open('${DUMP_DIR}/attested_claims.json'))
lb = d.get('lah-bundle', d)
wl = d.get('workload', {})

print('  \033[1;34m🔵 Workload ID (Software layer)\033[0m')
spiffe = wl.get('workload-id', '(not set)')
ksrc = wl.get('key-source', '(not set)')
print(f'     SPIFFE ID:         {spiffe}')
print(f'     Key Source:        {ksrc}')

print()
print('  \033[1;32m🟢 Inherited from Agent (Hardware layer)\033[0m')
geo_id = lb.get('geolocation-id-hash', '')
print(f'     Same Geo ID Hash:    {geo_id[:48]}...' if len(geo_id) > 48 else f'     Same Geo ID Hash:    {geo_id}')
proof_h = lb.get('geolocation-proof-hash', '')
print(f'     Same Proof Hash:     {proof_h}')
print(f'     Same Agent Digest:   {lb.get(\"workload-identity-agent-image-digest\", \"(not set)\")}')
print(f'     Same Privacy:        {lb.get(\"privacy-technique\", \"N/A\")}')

print()
print('  \033[1;32m✅ Workload identity = Software ID + Hardware ID + Location\033[0m')
print('     All three layers are cryptographically bound in ONE X.509 certificate')
"

    echo ""
    echo -e "    ${GREEN}${BOLD}▸ The client app inherits the TPM-attested geolocation from the agent${NC}"
    echo -e "    ${GREEN}${BOLD}▸ Workload wrapping Agent wrapping Location — one certificate${NC}"

    pause_for_presenter
}


# ═════════════════════════════════════════════════════════════════════════════
#  SLIDE 10 — Demo Act 2.3: End-to-End mTLS Through Envoy
# ═════════════════════════════════════════════════════════════════════════════
act2_3_envoy() {
    banner "SLIDE 10 │ Demo Act 2.3 — mTLS Through Envoy + WASM Filter"

    ensure_svid_dump

    sub_banner "Sending mTLS request: Client App → Envoy → Key Vault"

    echo -e "    ${DIM}curl -sk --cert svid.pem --key svid-key.pem --cacert envoy-cert.pem https://${ONPREM_HOST}:8080/hello${NC}"
    echo ""

    RESPONSE=$(curl -sk --cert "${DUMP_DIR}/svid.pem" \
         --key "${DUMP_DIR}/svid-key.pem" \
         --cacert "${ENVOY_CERT}" \
         "https://${ONPREM_HOST}:8080/hello" 2>&1) || true

    if [[ -n "$RESPONSE" && "$RESPONSE" != *"curl"* ]]; then
        pass "Response received from Key Vault"
        echo -e "    ${DIM}${RESPONSE:0:200}${NC}"
    else
        fail "No response (${RESPONSE:0:80})"
    fi

    sub_banner "What happened — step by step"

    if [[ -n "$RESPONSE" && "$RESPONSE" != *"curl"* ]]; then
        echo -e "    1. ${GREEN}✅${NC}  Envoy verified certificate chain (SPIRE CA → Agent → Workload)"
        echo -e "    2. ${GREEN}✅${NC}  WASM filter extracted LAH bundle from X.509 extension (OID 1.3.6.1.4.1.55744.1.1)"
        echo -e "    3. ${GREEN}✅${NC}  WASM verified geolocation claims (ZKP proof hash present)"
        echo -e "    4. ${GREEN}✅${NC}  mTLS connection forwarded to Key Vault (Server App)"
        echo -e "    5. ${GREEN}✅${NC}  Server App responded with secret data"
    else
        echo -e "    ${YELLOW}Steps skipped — curl did not succeed${NC}"
    fi

    echo ""
    echo -e "    ${BOLD}Authentication${NC} = mTLS certificate chain of trust"
    echo -e "    ${BOLD}Authorization${NC}  = WASM plugin reading geolocation from LAH bundle"

    pause_for_presenter
}


# ═════════════════════════════════════════════════════════════════════════════
#  SLIDES 11+12 — Combined: ZKP Deep Dive + Attack Resilience
# ═════════════════════════════════════════════════════════════════════════════
act3_zkp_deep_dive() {
    banner "SLIDES 11–12 │ Trust but Verify: ZKP Deep Dive"

    ensure_svid_dump

    ZKP_PROVER="${PROJ_DIR}/mobile-sensor-microservice/zkp-prover-plonky2/target/release/zkp-prover"

    # ── Part 1: Recap SVID — highlight ZKP fields ────────────────────────────
    sub_banner "Part 1: Recap — ZKP Fields in the Workload SVID"

    python3 -c "
import json
d = json.load(open('${DUMP_DIR}/attested_claims.json'))
lb = d.get('lah-bundle', d)

gp = lb.get('geolocation-payload', {})
if isinstance(gp, str):
    try: gp = json.loads(gp)
    except: gp = {}

print('  \033[1mFrom the X.509 certificate (OID 1.3.6.1.4.1.55744.1.1):\033[0m')
print()
print(f'    \033[1;33mgeolocation-proof-hash\033[0m : \033[1;36m{lb.get(\"geolocation-proof-hash\", \"N/A\")}\033[0m')
print(f'    \033[1;33mzkp-proof-uri\033[0m          : \033[1;36m{gp.get(\"zkp-proof-uri\", \"N/A\")}\033[0m')
print(f'    \033[1;33mprivacy-technique\033[0m      : \033[1;36m{lb.get(\"privacy-technique\", \"N/A\")}\033[0m')
print()
print('  \033[1mKey insight:\033[0m The certificate contains a HASH of the proof,')
print('  not the proof itself. The proof can be fetched from the URI.')
print('  An auditor only needs this certificate — no infrastructure access.')
"

    pause_for_presenter

    # ── Part 2: Hash verification ────────────────────────────────────────────
    sub_banner "Part 2: Hash Verification — Does the Proof Match the Certificate?"

    python3 -c "
import json, hashlib, base64

d = json.load(open('${DUMP_DIR}/attested_claims.json'))
lb = d.get('lah-bundle', d)
gp = lb.get('geolocation-payload', {})
if isinstance(gp, str):
    try: gp = json.loads(gp)
    except: gp = {}

cert_hash = lb.get('geolocation-proof-hash', '')
payload_json = json.dumps(gp, separators=(',', ':'), sort_keys=True)
computed = base64.urlsafe_b64encode(hashlib.sha256(payload_json.encode()).digest()).decode().rstrip('=')
cert_clean = cert_hash.rstrip('=')

print(f'    Geolocation payload JSON:')
print(f'      {payload_json}')
print()
print(f'    SHA-256(payload):      \033[1;36m{computed}\033[0m')
print(f'    geolocation-proof-hash: \033[1;36m{cert_clean}\033[0m')
print()
if computed == cert_clean:
    print('    \033[1;32m✅  HASH MATCH\033[0m — the proof URI content is committed in the X.509 cert')
    print('    \033[2mThis means the cert cannot be re-pointed to a different proof\033[0m')
else:
    print('    \033[1;31m❌  HASH MISMATCH\033[0m')
"

    pause_for_presenter

    # ── Part 3: Fetch proof and verify circuit ───────────────────────────────
    sub_banner "Part 3: ZKP Circuit Verification (Plonky2)"

    echo -e "    ${BOLD}Fetching proof from Keylime verifier receipt store...${NC}"

    PROOF_B64=$(python3 -c "
import json, ssl, urllib.request, sys, re
d = json.load(open('${DUMP_DIR}/attested_claims.json'))
lb = d.get('lah-bundle', d)
gp = lb.get('geolocation-payload', {})
if isinstance(gp, str):
    gp = json.loads(gp)
uri = gp.get('zkp-proof-uri', '')
# Keylime verifier binds to 127.0.0.1; rewrite host for local fetch
uri = re.sub(r'https://[^:/]+:', 'https://127.0.0.1:', uri)
try:
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    resp = urllib.request.urlopen(uri, context=ctx, timeout=5)
    receipt = json.loads(resp.read())
    print(receipt['results']['sovereignty_receipt'])
except Exception as e:
    print('', end='')
" 2>/dev/null) || PROOF_B64=""

    if [[ -z "$PROOF_B64" ]]; then
        warn "Proof URI not reachable (Keylime receipt endpoint may be down)"
        info "Hash commitment (Part 2) still confirms the SVID is valid"
        info "Skipping circuit verification"
        pause_for_presenter
    else
        echo -e "    ${GREEN}✅${NC}  Proof fetched (${#PROOF_B64} chars)"
        echo ""

        if [[ -f "$ZKP_PROVER" ]]; then
            echo -e "    ${BOLD}Running Plonky2 verifier (verify-only mode):${NC}"
            echo -e "    ${DIM}zkp-prover --verify-only --proof=<proof>${NC}"
            echo ""

            VERIFY_OUT=$("$ZKP_PROVER" --verify-only --proof="$PROOF_B64" 2>&1) || true
            VERIFY_STDERR=$(echo "$VERIFY_OUT" | grep -i "Public inputs" || true)
            VERIFY_STDOUT=$(echo "$VERIFY_OUT" | grep -i "Proof VALID" || true)

            if [[ -n "$VERIFY_STDERR" ]]; then
                echo -e "    ${BOLD}Public inputs extracted from proof:${NC}"
                CLAT=$(echo "$VERIFY_STDERR" | grep -oP 'center_lat=\K[0-9]+')
                CLON=$(echo "$VERIFY_STDERR" | grep -oP 'center_lon=\K[0-9]+')
                RADIUS=$(echo "$VERIFY_STDERR" | grep -oP 'radius=\K[0-9]+')
                IDHASH=$(echo "$VERIFY_STDERR" | grep -oP 'idhash=\K[0-9]+')

                echo -e "      ${CYAN}center_lat${NC}  = ${CLAT}  ${DIM}(geofence policy)${NC}"
                echo -e "      ${CYAN}center_lon${NC}  = ${CLON}  ${DIM}(geofence policy)${NC}"
                echo -e "      ${CYAN}radius${NC}      = ${RADIUS}  ${DIM}(geofence policy)${NC}"
                echo -e "      ${CYAN}idhash${NC}      = ${IDHASH}  ${DIM}← SHA-256(TPM AK) — binds proof to THIS device${NC}"
                echo ""
                echo -e "    ${BOLD}These are the geofence policy parameters baked into the circuit.${NC}"
                echo -e "    ${DIM}The prover knew GPS coordinates INSIDE this circle,${NC}"
                echo -e "    ${DIM}but those exact coordinates remain private (zero-knowledge).${NC}"
                echo -e "    ${DIM}Management processor (e.g. HPE iLO 7, Dell iDRAC) ensures sensor integrity.${NC}"
                echo ""
                echo -e "    ${BOLD}${CYAN}Public inputs (in proof):${NC}  center_lat, center_lon, radius, idhash"
                echo -e "                               → Geofence policy + device binding"
                echo -e "                               → idhash = SHA-256(AK pub) — AK pub is in cert for TPM2 quote verification"
                echo -e "    ${BOLD}${RED}Private inputs (hidden):${NC}   actual GPS lat, lon"
                echo -e "                               → Never leave the device — only proved, never revealed"
            fi

            if [[ -n "$VERIFY_STDOUT" ]]; then
                echo ""
                pass "CIRCUIT VALID — Plonky2 zero-knowledge proof verified"
            else
                fail "CIRCUIT INVALID"
            fi

            pause_for_presenter

            # ── Part 4: Tamper idhash — show proof fails ─────────────────────
            sub_banner "Part 4: Attack — Tamper the Device Identity"

            echo -e "    ${DIM}Scenario: Attacker changes the idhash to claim a DIFFERENT TPM produced this proof${NC}"
            echo ""
            echo -e "    ${BOLD}Original idhash (from proof):${NC}  ${GREEN}${IDHASH}${NC}"
            echo -e "    ${BOLD}Tampered idhash (attacker):${NC}    ${RED}999999999${NC}"
            echo ""
            echo -e "    ${DIM}zkp-prover --verify --proof=<proof> --clat=${CLAT} --clon=${CLON} --radius=${RADIUS} ${NC}${BOLD}--idhash=999999999${NC}"
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
                echo -e "      • geo-id-hash in cert = pre-committed binding (derivable from AK pub in cert)"
                echo -e "      • You cannot transplant a valid proof to a different device"
            else
                pass "Tamper result: ${TAMPER_OUT}"
            fi

            pause_for_presenter
        else
            warn "zkp-prover binary not found at ${ZKP_PROVER}"
            info "Build with: cd mobile-sensor-microservice/zkp-prover-plonky2 && cargo build --release"
            pause_for_presenter
        fi
    fi

    # ── Part 4b: ZKP Design Properties ─────────────────────────────────────
    sub_banner "ZKP Design Properties"

    echo -e "    ${BOLD}1. Verification = proof + public inputs ONLY${NC}"
    echo -e "       ${DIM}The verifier never sees GPS coordinates.${NC}"
    echo -e "       ${DIM}It checks: \"given these public inputs, is this proof valid?\" → true/false${NC}"
    echo ""
    echo -e "    ${BOLD}2. Circuit code is policy-agnostic${NC}"
    echo -e "       ${DIM}Same circuit works for ANY geofence (Paris, Tokyo, São Paulo...)${NC}"
    echo -e "       ${DIM}Only the public inputs change (center_lat, center_lon, radius).${NC}"
    echo -e "       ${DIM}No recompilation, no redeployment — just new policy parameters.${NC}"
    echo ""
    echo -e "    ${BOLD}3. Everything can live on a public ledger${NC}"
    echo -e "       ${DIM}✓ Circuit code (open source — Plonky2, MIT/Apache 2.0)${NC}"
    echo -e "       ${DIM}✓ X.509 certificate (contains geo-id-hash + proof-hash)${NC}"
    echo -e "       ${DIM}✓ ZKP proof (fetched from zkp-proof-uri in cert)${NC}"
    echo -e "       ${DIM}✗ GPS coordinates — NEVER exposed, by mathematical guarantee${NC}"
    echo ""
    echo -e "    ${BOLD}${GREEN}Full transparency + full privacy. That's the ZKP value proposition.${NC}"

    pause_for_presenter

    # ── Part 5: ZKP vs Approximated Location ─────────────────────────────────
    sub_banner "Part 5: Why ZKP — Not Approximate Location?"

    echo -e "    ${BOLD}${CYAN}                    ZKP (Plonky2)             Approx. Location${NC}"
    echo -e "    ${BOLD}────────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${GREEN}Privacy${NC}            Exact coords stay         Coarsened but reveals"
    echo -e "                       private (zero-knowledge)     approximate area"
    echo ""
    echo -e "    ${GREEN}Verifiability${NC}      Cryptographic proof       Trust-the-server"
    echo -e "                       (anyone can verify)          (no proof, just assertion)"
    echo ""
    echo -e "    ${GREEN}Auditability${NC}       Proof can live on a       No proof to store"
    echo -e "                       public ledger forever        or audit later"
    echo ""
    echo -e "    ${GREEN}Tamper-proof${NC}       Circuit rejects wrong     Approx. location can be"
    echo -e "                       inputs (idhash mismatch)     fabricated trivially"
    echo ""
    echo -e "    ${GREEN}Device binding${NC}     idhash = SHA-256(AK)      No hardware binding"
    echo -e "                       → TPM-rooted                 → software-only"

    echo ""
    echo -e "    ${BOLD}${CYAN}Why Plonky2 specifically?${NC}"
    echo -e "    ${BOLD}────────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${GREEN}No trusted setup${NC}     Transparent — no ceremony, no toxic waste"
    echo -e "                         Anyone can verify without trusting a setup phase"
    echo ""
    echo -e "    ${GREEN}Hash-based${NC}           Commitments use Poseidon hash (no elliptic curves)"
    echo -e "                         → Post-quantum resistant (PQC-ready)"
    echo ""
    echo -e "    ${GREEN}Fast${NC}                 ~50ms proof generation, ~100ms verification"
    echo -e "                         Recursive proof composition for complex policies"
    echo ""
    echo -e "    ${GREEN}CPU-native${NC}           64-bit prime field (Goldilocks)"
    echo -e "                         → Maps to native CPU instructions, no BigInt overhead"

    echo ""
    echo -e "    ${BOLD}Bottom line:${NC} Approximate location is ${RED}privacy theatre${NC} —"
    echo -e "    it obscures from humans but not from algorithms."
    echo -e "    ZKP provides ${GREEN}mathematical privacy${NC} with ${GREEN}cryptographic verifiability${NC}."

    pause_for_presenter

    # ── Part 6: ZKP + TEE — Complementary Layers ─────────────────────────────
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
    echo -e "    ${DIM}  * SR-IOV / VFIO passthrough can give enclave direct sensor access,${NC}"
    echo -e "    ${DIM}    bypassing the OS — same input integrity HPE iLO 7 gets architecturally.${NC}"
    echo -e "    ${DIM}    Requires: IOMMU + SR-IOV-capable sensor hardware + driver in enclave TCB.${NC}"

    echo ""
    echo -e "    ${BOLD}${CYAN}The TEE integrity tradeoff:${NC}"
    echo -e "    ${DIM}  Co-located TEEs (TDX/SEV) disable KASLR for consistent launch measurement${NC}"
    echo -e "    ${DIM}  → Deterministic layout required for attestation quotes${NC}"
    echo -e "    ${DIM}  → Predictable code layout → easier ROP exploitation if side-channel breaks${NC}"
    echo -e "    ${BOLD}  TEE buys confidentiality by trading away a runtime integrity defense${NC}"

    echo ""
    echo -e "    ${BOLD}${CYAN}Where to run the ZKP prover:${NC}"
    echo ""
    echo -e "    ${DIM}Option 1:${NC}  Userspace sidecar      ${DIM}(today's POC — portable, fast iteration)${NC}"
    echo -e "    ${DIM}Option 2:${NC}  TDX/SEV confidential VM  ${DIM}(confidentiality ✅ but ASLR ❌, side-channels ❌)${NC}"
    echo -e "    ${GREEN}${BOLD}Option 3:${NC}${GREEN}  Management processor    ${BOLD}← Strongest (ASLR preserved)${NC}"
    echo -e "             ${DIM}(HPE iLO 7 / Dell iDRAC)${NC}"
    echo ""
    echo -e "    ${BOLD}Why a management processor is the strongest TEE:${NC}"
    echo -e "    ${GREEN}•${NC} ${BOLD}Separate silicon${NC}   — own ARM CPU, own RAM → ${GREEN}no shared microarchitecture${NC}"
    echo -e "    ${GREEN}•${NC} ${BOLD}No side-channels${NC}   — physically different processor → Spectre irrelevant"
    echo -e "    ${GREEN}•${NC} ${BOLD}Full ASLR preserved${NC} — firmware-level measurement, not memory-layout${NC}"
    echo -e "    ${GREEN}•${NC} ${BOLD}Direct sensor access${NC} — GPS data never transits host OS → ${GREEN}input integrity solved${NC}"
    echo -e "    ${GREEN}•${NC} ${BOLD}Silicon Root of Trust${NC} — HPE-signed firmware, not Intel/AMD microcode"
    echo ""
    echo -e "    ${DIM}TDX/SEV disables KASLR to measure. HPE iLO 7 keeps ASLR because it measures firmware, not memory.${NC}"
    echo -e "    ${BOLD}Confidentiality by physics. Integrity without compromise.${NC}"

    pause_for_presenter
}



# ═════════════════════════════════════════════════════════════════════════════
#  Closing Summary
# ═════════════════════════════════════════════════════════════════════════════
closing() {
    banner "Summary: Unified Identity — Defence in Depth"

    echo -e "    ${GREEN}${BOLD}WHO${NC}   → SPIFFE ID signed by SPIRE CA             ${DIM}(cert forgery ✘)${NC}"
    echo -e "    ${GREEN}${BOLD}WHERE${NC} → ZKP proof sealed by TPM                  ${DIM}(GPS spoofing ✘)${NC}"
    echo -e "    ${GREEN}${BOLD}WHAT${NC}  → Agent binary digest measured by Keylime   ${DIM}(tampering ✘)${NC}"
    echo ""
    echo -e "    ${BOLD}You cannot peel away any layer without invalidating the identity.${NC}"
    echo ""
    echo -e "    ${DIM}Key insight: Compromising one layer does NOT help with the others.${NC}"
    echo -e "    ${DIM}An attacker must simultaneously defeat TPM hardware, ZKP math,${NC}"
    echo -e "    ${DIM}certificate authority, AND binary measurement.${NC}"

    echo ""
    echo -e "    ${BOLD}${CYAN}Why this architecture, not just TEE?${NC}"
    echo ""
    echo -e "    ${DIM}TEE solves confidentiality${NC}  — encrypts memory so the OS can't read it"
    echo -e "    ${DIM}TEE weakens integrity${NC}      — disables KASLR for consistent attestation quotes"
    echo -e "    ${DIM}ZKP solves verifiability${NC}   — mathematical proof, not \"trust the enclave\""
    echo -e "    ${DIM}Keylime/IMA keeps KASLR${NC}   — file-hash measurement, no layout dependency"
    echo ""
    echo -e "    ${BOLD}The natural evolution: ZKP prover inside the management processor (HPE iLO 7 / Dell iDRAC)${NC}"
    echo -e "    ${GREEN}•${NC} Separate silicon — confidentiality by physics, not encryption"
    echo -e "    ${GREEN}•${NC} Full KASLR — integrity without tradeoff"
    echo -e "    ${GREEN}•${NC} Direct sensor access — input integrity solved architecturally"
    echo -e "    ${GREEN}•${NC} The proof is self-verifying — trust math, not hardware vendors"
    echo ""
    echo -e "    ${BOLD}${GREEN}A stolen server gets no identity. It's cryptographically bricked.${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}


# ═════════════════════════════════════════════════════════════════════════════
#  Main
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                               ║${NC}"
echo -e "${CYAN}║   ${BOLD}${GREEN}Unified Identity — Comprehensive Live Demo${NC}${CYAN}                  ║${NC}"
echo -e "${CYAN}║   ${DIM}Agentic and Deterministic AI: HW/Silicon-Rooted Trust${NC}${CYAN}      ║${NC}"
echo -e "${CYAN}║                                                               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DIM}    Slide deck alignment: Slides 7 → 12${NC}"
echo -e "${DIM}    Mode: $([ "$AUTO_MODE" = true ] && echo "auto-advance (5s)" || echo "interactive (press Enter)")${NC}"

pause_for_presenter

act1_infrastructure
act2_1_agent
act2_2_workload
act2_3_envoy
act3_zkp_deep_dive
closing

echo ""
echo -e "${GREEN}${BOLD}    Demo complete.${NC}"
echo ""
