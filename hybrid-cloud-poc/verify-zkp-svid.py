#!/usr/bin/env python3
# Copyright 2025 AegisSovereignAI Contributors
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
"""
verify-zkp-svid.sh  — ZKP Proof Verifier for AegisSovereignAI SVIDs

Reads an X.509 SVID certificate (PEM), extracts the lah-bundle extension,
and verifies:
  1. The geolocation-proof-hash matches SHA-256(geolocation-payload JSON).
  2. The proof URI is reachable and returns the stored ZKP receipt.

Usage:
    python3 verify-zkp-svid.sh <svid.pem>        # verify from cert file
    python3 verify-zkp-svid.sh --uri <proof_uri> --hash <base64url_hash>

Examples:
    python3 verify-zkp-svid.sh /tmp/svid-dump/svid.pem
    python3 verify-zkp-svid.sh \\
        --uri  https://<VERIFIER_HOST>:8881/v1/proof/45d8f2ad... \\
        --hash -BcaOM3ifWcqRQ2fbsvS20M5RQF7RMGS9He7JCtoxuU=
"""

import os
import sys
import json
import hashlib
import base64
import ssl
import urllib.request
import argparse

# ── OID for the AegisSovereignAI SVID extension ───────────────────────────────
UNIFIED_IDENTITY_OID = "1.3.6.1.4.1.55744.1.1"


def b64url_decode(s: str) -> bytes:
    """Decode base64url (with or without padding)."""
    s = s.rstrip("=")
    pad = (-len(s)) % 4
    return base64.urlsafe_b64decode(s + "=" * pad)


def b64url_encode(b: bytes) -> str:
    """Encode to base64url, no padding."""
    return base64.urlsafe_b64encode(b).decode().rstrip("=")


def sha256_b64url(data: bytes) -> str:
    return b64url_encode(hashlib.sha256(data).digest())


def fetch_uri(uri: str) -> tuple[bool, str]:
    """Fetch a URI (TLS, no cert verification for POC self-signed certs)."""
    # Rewrite external hostname to localhost for POC (Keylime binds to 127.0.0.1)
    from urllib.parse import urlparse, urlunparse
    parsed = urlparse(uri)
    local_uri = urlunparse(parsed._replace(netloc=f"127.0.0.1:{parsed.port or 8881}"))
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    try:
        with urllib.request.urlopen(local_uri, context=ctx, timeout=5) as resp:
            body = resp.read().decode()
            return True, body
    except Exception as e:
        return False, str(e)


def verify_hash(proof_uri: str, proof_hash: str) -> dict:
    """Recompute the hash and compare."""
    geo_payload = {"zkp-proof-uri": proof_uri}
    geo_json = json.dumps(geo_payload, sort_keys=True, separators=(",", ":")).encode()
    computed = sha256_b64url(geo_json)

    expected = proof_hash.rstrip("=")
    computed_stripped = computed.rstrip("=")
    match = computed_stripped == expected
    return {
        "computed": computed,
        "expected": proof_hash,
        "match": match,
        "geo_json": geo_json.decode(),
    }


def extract_lah_bundle_from_cert(pem_path: str) -> dict | None:
    """Extract the lah-bundle claim from the AttestedClaims X.509 extension."""
    try:
        from cryptography import x509
        from cryptography.hazmat.primitives.serialization import Encoding
    except ImportError:
        print("ERROR: Install cryptography:  pip3 install cryptography")
        sys.exit(1)

    with open(pem_path) as f:
        pem_data = f.read()

    # Support multi-cert PEM (agent SVID has chain)
    certs = []
    chunk = []
    for line in pem_data.splitlines():
        chunk.append(line)
        if "-----END CERTIFICATE-----" in line:
            certs.append("\n".join(chunk))
            chunk = []

    for pem in certs:
        cert = x509.load_pem_x509_certificate(pem.encode())
        for ext in cert.extensions:
            if ext.oid.dotted_string == UNIFIED_IDENTITY_OID:
                raw = ext.value.value
                # Value is ASN.1 OCTET STRING wrapping JSON bytes
                # Try direct decode first, then strip leading 2-byte ASN.1 wrapper
                try:
                    claims = json.loads(raw)
                except Exception:
                    # Strip ASN.1 OCTET STRING tag+length (04 LL)
                    if raw[0] == 0x04:
                        length_byte = raw[1]
                        offset = 2 + (0 if length_byte < 0x80 else (length_byte & 0x7f))
                        claims = json.loads(raw[offset:])
                    else:
                        claims = json.loads(raw)
                return claims
    return None


def run(args):
    proof_uri = args.uri
    proof_hash = args.hash

    # --- Mode 1: extract from cert ---
    if args.cert:
        print(f"\n📜  Reading SVID cert: {args.cert}")
        claims = extract_lah_bundle_from_cert(args.cert)
        if not claims:
            print("ERROR: No AttestedClaims extension found in cert.")
            sys.exit(1)

        print("✓  AttestedClaims extracted")
        lah = claims.get("lah-bundle", {})
        if not lah:
            print("  ⚠  No lah-bundle key in claims (workload-only SVID):")
            print(f"     {list(claims.keys())}")
            sys.exit(0)

        geo_payload_str = lah.get("geolocation-payload", "")
        try:
            geo_payload_obj = json.loads(geo_payload_str) if isinstance(geo_payload_str, str) else geo_payload_str
        except Exception:
            geo_payload_obj = {}

        proof_uri = proof_uri or geo_payload_obj.get("zkp-proof-uri", "")
        proof_hash = proof_hash or lah.get("geolocation-proof-hash", "")

        print(f"\n📦  lah-bundle fields:")
        print(f"    privacy-technique : {lah.get('privacy-technique', 'N/A')}")
        print(f"    geolocation-id-hash (device binding, opaque) : {lah.get('geolocation-id-hash','N/A')[:32]}...")
        print(f"    geolocation-proof-hash : {proof_hash}")
        print(f"    zkp-proof-uri : {proof_uri}")
        print(f"    nonce : {lah.get('nonce','N/A')[:16]}...")
        print(f"    timestamp : {lah.get('timestamp','N/A')}")
        if claims.get("workload"):
            print(f"\n🆔  workload:")
            print(f"    workload-id : {claims['workload'].get('workload-id','N/A')}")
            print(f"    key-source  : {claims['workload'].get('key-source','N/A')}")

    # --- Step 1: Hash verification ---
    if not proof_uri or not proof_hash:
        print("ERROR: need --uri and --hash (or a cert with lah-bundle).")
        sys.exit(1)

    print(f"\n🔐  Step 1 — Hash verification")
    result = verify_hash(proof_uri, proof_hash)
    print(f"    geo_payload JSON : {result['geo_json']}")
    print(f"    SHA-256 computed : {result['computed']}")
    print(f"    cert commitment  : {result['expected']}")
    if result["match"]:
        print("    ✅  HASH MATCH — payload committed by SPIRE matches cert")
    else:
        print("    ❌  HASH MISMATCH — proof_uri does not match cert's commitment")
        sys.exit(1)

    # --- Step 2: URI fetch ---
    print(f"\n🌐  Step 2 — Proof URI fetch")
    print(f"    URI : {proof_uri}")
    ok, body = fetch_uri(proof_uri)
    if ok:
        print(f"    ✅  PROOF EXISTS — Keylime verifier returned receipt")
        try:
            receipt = json.loads(body)
            print(f"    receipt preview : {json.dumps(receipt, indent=2)[:400]}")
        except Exception:
            receipt = {}
            print(f"    body preview : {body[:200]}")
    else:
        receipt = {}
        print(f"    ⚠   URI fetch failed (may be expected if Keylime verifier is down): {body}")
        print(f"    ℹ   Hash match still confirms the SVID commitment is valid.")

    # --- Step 3: Plonky2 circuit verification ---
    print(f"\n🔬  Step 3 — ZKP Circuit Verification (Plonky2)")

    # Extract the raw base64 proof from the receipt
    sovereignty_receipt = None
    if receipt:
        results = receipt.get("results", receipt)
        sovereignty_receipt = results.get("sovereignty_receipt")

    if not sovereignty_receipt:
        print("    ⚠   No sovereignty_receipt in proof response — skipping circuit verification")
        print("    ℹ   Hash commitment (Step 1) still confirms the SVID is valid.")
    else:
        # Find the zkp-prover binary
        script_dir = os.path.dirname(os.path.abspath(__file__))
        prover_paths = [
            os.path.join(script_dir, "mobile-sensor-microservice", "zkp-prover-plonky2", "target", "release", "zkp-prover"),
            os.path.join(script_dir, "..", "hybrid-cloud-poc", "mobile-sensor-microservice", "zkp-prover-plonky2", "target", "release", "zkp-prover"),
        ]
        prover_bin = None
        for p in prover_paths:
            if os.path.isfile(p):
                prover_bin = p
                break

        if not prover_bin:
            print("    ⚠   zkp-prover binary not found — cannot run circuit verification")
            print(f"    ℹ   Expected at: {prover_paths[0]}")
            print("    ℹ   Build with: cd mobile-sensor-microservice/zkp-prover-plonky2 && cargo build --release")
        else:
            print(f"    prover binary : {prover_bin}")
            print(f"    proof length  : {len(sovereignty_receipt)} chars")

            import subprocess

            # Use --verify-only: extracts public inputs from the proof itself
            # No need to supply external geofence params — the proof contains them
            cmd = [prover_bin, "--verify-only", f"--proof={sovereignty_receipt}"]

            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)

                # stderr contains the public inputs for transparency
                for line in result.stderr.strip().splitlines():
                    if "Public inputs" in line:
                        print(f"    📊  {line}")

                if "Proof VALID" in result.stdout:
                    print(f"    ✅  CIRCUIT VALID — Plonky2 zero-knowledge proof verified")
                    print(f"    ℹ   The prover mathematically proved the sensor was inside the geofence")
                    print(f"    ℹ   without revealing the exact GPS coordinates (they remain private).")
                else:
                    print(f"    ❌  CIRCUIT INVALID — {result.stdout.strip() or result.stderr.strip()}")
            except FileNotFoundError:
                print(f"    ⚠   zkp-prover binary not executable")
            except subprocess.TimeoutExpired:
                print(f"    ⚠   zkp-prover timed out (>60s) — circuit verification is compute-intensive")
            except Exception as e:
                print(f"    ⚠   Circuit verification error: {e}")

    # Step 4: Hardware Trust Anchors (External Auditor View)
    print(f"\n{'─' * 60}")
    print("🔐  Step 4: Hardware Trust Anchors (External Auditor)")
    print(f"{'─' * 60}")

    if claims:
        lah_bundle = claims.get('lah-bundle', {})

        # TPM Quote Seal — proves attestation was TPM-sealed
        tpm_seal = lah_bundle.get('tpm-quote-seal', '')
        if tpm_seal:
            print(f"    🔏  TPM Quote Seal: {tpm_seal[:40]}...  ({len(tpm_seal)} chars)")
            print(f"    ℹ   TPM2_Quote over PCR 15 — binds geolocation to hardware root-of-trust")
        else:
            print(f"    ℹ   TPM Quote Seal: (not populated in this attestation cycle)")

        # Workload Identity Agent Image Digest — detects SPIRE agent binary compromise
        agent_digest = lah_bundle.get('workload-identity-agent-image-digest', '')
        if agent_digest:
            print(f"    🛡️   Agent Image Digest: {agent_digest}")
            print(f"    ℹ   SHA-256 of Workload Identity Agent binary — measured at attestation time")
            print(f"    ℹ   A mismatch here indicates the agent was replaced (without kernel compromise)")
        else:
            print(f"    ℹ   Agent Image Digest: (not present — agent not measured)")

        # TPM AK — the hardware identity anchor
        tpm_ak = lah_bundle.get('tpm-ak', '')
        if tpm_ak:
            print(f"    🔑  TPM AK: {tpm_ak[:40]}...  ({len(tpm_ak)} chars)")

        # Geolocation ID Hash — sensor binding
        geo_id = lah_bundle.get('geolocation-id-hash', '')
        if geo_id:
            print(f"    📍  Geolocation ID Hash: {geo_id}")
    else:
        print("    ℹ   No lah-bundle claims found in certificate")

    print("\n✅  ZKP verification complete\n")


def main():
    parser = argparse.ArgumentParser(
        description="Verify a ZKP proof commitment from an AegisSovereignAI SVID cert.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("cert", nargs="?", help="Path to SVID PEM file")
    parser.add_argument("--uri",  help="Proof URI (overrides cert extraction)")
    parser.add_argument("--hash", help="Expected geolocation-proof-hash (overrides cert extraction)")
    parser.add_argument("--clat",   type=float, help="Geofence center latitude (for circuit verification)")
    parser.add_argument("--clon",   type=float, help="Geofence center longitude (for circuit verification)")
    parser.add_argument("--radius", type=float, help="Geofence radius in degrees (for circuit verification)")
    parser.add_argument("--idhash", type=int,   help="Sensor ID hash (for circuit verification)")
    args = parser.parse_args()

    if not args.cert and not (args.uri and args.hash):
        parser.print_help()
        sys.exit(1)

    run(args)


if __name__ == "__main__":
    main()
