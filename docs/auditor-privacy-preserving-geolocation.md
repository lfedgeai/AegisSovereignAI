# Privacy-Preserving Geolocation Verification for Auditors

> **For Technical Auditors & Architects:** This document provides a deep-dive on **privacy-preserving geolocation verification** for regulatory compliance (e.g., Reg-K, GDPR). For the underlying hardware and identity architecture, see **[Unified Identity & Trust Framework](../hybrid-cloud-poc/README-arch-sovereign-unified-identity.md)**. For Layer 3 AI governance, see **[Privacy-Preserving AI Governance](./auditor-privacy-preserving-ai-governance.md)**.

---

## 1. The Problem: The Residency vs. Privacy Deadlock

Regulators require **proof of data residency** (e.g., **Regulation K**), but traditional geofencing creates a fundamental conflict:

| Requirement | Traditional Approach | Liability / Risk |
|-------------|---------------------|------------------|
| **Prove Data Residency** | Log precise GPS coordinates | Creates massive PII liability under GDPR |
| **Comply with GDPR** | Don't store location data | Cannot prove Reg-K compliance |
| **Prevent Location Spoofing** | Rely on IP-based geofencing | Trivially bypassed with VPNs |

**The Deadlock:** Enterprises are forced to choose between **non-compliance with residency laws** or **privacy violation under GDPR**.

---

## 2. Privacy-Preserving Techniques: A Technical Comparison

Multiple Privacy-Enhancing Technologies (PETs) exist for protecting location data. Below is an analysis of why **Zero-Knowledge Proofs (ZKPs)** are optimal for geolocation compliance.

| Technology | How It Works | Pros | Cons for Geolocation |
|------------|--------------|------|----------------------|
| **Trusted Execution Environments (TEEs)** | Process location inside hardware enclaves (Intel SGX, AMD SEV) | Low overhead, real-time processing | Requires external auditor to trust the enclave; no portable proof for regulators |
| **Homomorphic Encryption (FHE)** | Compute on encrypted coordinates without decryption | Strong mathematical guarantees | **1000x+ overhead** makes real-time geofencing impractical |
| **Secure Multi-Party Computation (MPC)** | Distribute computation across multiple parties | No single party sees full data | Network latency; operational complexity for mobile devices |
| **Differential Privacy** | Add noise to location data | Protects individual coordinates | **Cannot prove exact boundary compliance** (noise defeats precision) |
| **Zero-Knowledge Proofs (ZKPs)** | Prove statement about data without revealing data | Portable proof; auditor-verifiable; no data retention | Proof generation overhead (mitigated by batching) |

### Why ZKP is Optimal for Geolocation Compliance

1. **Portable Proof:** Unlike TEEs, ZKPs produce a proof that can be verified by any auditor without trusting specific hardware.
2. **Exact Compliance:** Unlike Differential Privacy, ZKPs prove the coordinate is **exactly** within the boundary—no approximations.
3. **No Retained Data:** The proof is generated device-side; raw coordinates never leave the device.
4. **Auditor Independence:** Regulators verify the mathematical proof, not the Enterprise's attestation claims.
5. **Batching for Performance:** While individual proof generation has overhead, session-level batching amortizes costs.

> [!NOTE]
> **AegisSovereignAI Hybrid Approach:** We combine **TEEs** (for secure real-time filtering) with **ZKPs** (for auditor-verifiable compliance proofs), achieving both performance and regulatory portability.

---

## 3. The AegisSovereignAI Solution: Hardware-Rooted Privacy-Preserving Geofencing

AegisSovereignAI resolves this deadlock using a **"Coordinate-in-Polygon" ZKP circuit** combined with hardware-rooted sensor fusion.

### The Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PRIVACY-PRESERVING GEOLOCATION FLOW                      │
└─────────────────────────────────────────────────────────────────────────────┘

  Device (BYOD/Managed)              Aegis Verifier              Auditor
  ═══════════════════════            ══════════════              ════════

  ┌──────────────────────┐
  │  Hardware Sensors    │
  │  (TPM-signed GPS +   │
  │   CAMARA Mobile API) │
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │  ZKP Circuit Engine  │
  │  (Coordinate-in-     │
  │   Polygon Proof)     │
  └──────────┬───────────┘
             │
             │  Private: Precise GPS coordinates
             │  Public: Compliance boundary polygon
             │
             ▼
  ┌──────────────────────┐          ┌─────────────────────┐
  │  ZKP Proof Generated │────────▶│  Verify ZKP Proof   │
  │  (No raw GPS sent)   │          │  + Hardware Quote   │
  └──────────────────────┘          └──────────┬──────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │  SVID Issued with   │
                                    │  Geolocation Claim: │
                                    │  • status: COMPLIANT│
                                    │  • region: US-EAST  │──────▶ Evidence
                                    │  • proof: base64... │        Bundle
                                    └─────────────────────┘

  🔑 KEY INSIGHT: The Enterprise never sees raw GPS coordinates.
     The auditor receives a cryptographic proof of compliance.
```

### The ZKP Circuit

```rust
// Conceptual Noir Circuit for Privacy-Preserving Geofencing
fn main(
    // PRIVATE INPUTS (Never disclosed)
    gps_latitude: Field,           // User's precise latitude
    gps_longitude: Field,          // User's precise longitude
    sensor_signature: [u8; 64],    // TPM signature over coordinates
    
    // PUBLIC INPUTS (Visible to auditor)
    compliance_polygon: [Point; N], // The "Green Zone" boundary
    tpm_public_key: pub Field,      // For signature verification
    proof_timestamp: pub Field      // When the proof was generated
) {
    // 1. Verify the coordinates came from genuine hardware
    assert(verify_tpm_signature(
        sensor_signature, 
        hash(gps_latitude, gps_longitude, proof_timestamp),
        tpm_public_key
    ));
    
    // 2. Verify the point is inside the compliance polygon
    assert(point_in_polygon(
        gps_latitude, 
        gps_longitude, 
        compliance_polygon
    ));
    
    // OUTPUT: Proof that "genuine hardware reported a location within the boundary"
    // WITHOUT revealing the actual coordinates
}
```

### TPM-Signed ZKP Output: End-to-End Hardware Binding

For **absolute privacy guarantees**, the ZKP proof itself is signed by the TPM on the Keylime-attested host. This ensures the proof was generated on a specific verified server and cannot be replayed from elsewhere.

```
┌─────────────────────────────────────────────────────────────────────────┐
│              TPM-SIGNED ZKP OUTPUT (KEYLIME AGENT PLUGIN)               │
└─────────────────────────────────────────────────────────────────────────┘

  Keylime Agent Plugin                                    Auditor
  ════════════════════                                    ════════

  ┌──────────────────────┐
  │  1. TPM-Signed       │   (Input attestation)
  │     GPS Coordinates  │
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │  2. ZKP Circuit      │   (Privacy-preserving computation)
  │     Generates Proof  │
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │  3. TPM Signs        │   (Output attestation)
  │     Proof Hash       │
  │     ────────────     │
  │     proof_hash =     │
  │       SHA256(zkp)    │
  │     output_sig =     │
  │       TPM_Sign(      │
  │         proof_hash)  │
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐          ┌─────────────────────┐
  │  ZKP Proof +         │────────▶│  Verify:            │
  │  TPM Output Sig      │          │  • ZKP is valid     │
  └──────────────────────┘          │  • Output sig binds │
                                    │    proof to TPM     │
                                    └─────────────────────┘
```

**Why This Matters:**
1. **Input Binding:** TPM-signed coordinates prove the GPS came from genuine hardware
2. **Output Binding:** TPM-signed proof hash proves the ZKP was generated on **that specific Keylime-attested server**
3. **No Replay:** An attacker cannot generate a valid ZKP elsewhere and replay it—the output signature would fail TPM verification

> [!NOTE]
> **Performance Impact:** Geolocation proofs are refreshed every 1-5 minutes (not per-request). At this frequency, the ~100ms TPM signing overhead is negligible.

---


## 4. Multi-Sensor Fusion: Defeating Spoofing Attacks

AegisSovereignAI uses **hardware-rooted multi-sensor fusion** to prevent location spoofing. This builds on the architecture detailed in the **[Unified Identity & Trust Framework](../hybrid-cloud-poc/README-arch-sovereign-unified-identity.md)**.

### Sensor Hierarchy

| Sensor Type | Trust Level | Verification Method |
|-------------|-------------|---------------------|
| **CAMARA Mobile API** | Highest | MNO-verified SIM location via OIDC |
| **TPM-Signed GNSS** | High | Hardware-rooted GPS signatures |
| **App-Level GPS** | Low | Cross-validated against higher-trust sensors |

### Attack Resistance

| Attack Vector | Traditional Vulnerability | Aegis Defense |
|---------------|---------------------------|---------------|
| **VPN Spoofing** | IP-based checks fail | Hardware sensors ignore network layer |
| **GPS Spoofing App** | App-level coordinates faked | TPM signature verification fails |
| **Frida/API Hooking** | Runtime API interception | CAMARA API bypasses app layer entirely |
| **Rooted/Jailbroken Device** | Full sensor control | Secure Enclave attestation detects compromise |

> **Deep-Dive:** For complete attack analysis, see **[Threat Model: Unmanaged Device Security](../hybrid-cloud-poc/THREAT-MODEL-unmanaged-device.md)**.

---

## 5. The SVID Geolocation Claims

When geolocation verification succeeds, the claims are embedded in the **SPIFFE Verifiable Identity Document (SVID)**:

```json
{
  "svid": "spiffe://aegis.local/workload/private-wealth-advisory",
  "claims": {
    "grc.geolocation.status": "compliant",
    "grc.geolocation.region_id": "US-EAST-1",
    "grc.geolocation.proof": "base64-zkp-proof...",
    "grc.geolocation.timestamp": "2026-01-20T14:00:00Z",
    "grc.geolocation.sensor_type": "CAMARA_MNO",
    "grc.tpm-attestation.tier": "tier-2-byod"
  },
  "attestation_quote": "base64-tpm-quote..."
}
```

### Claim Semantics

| Claim | Type | Example | Description |
|-------|------|---------|-------------|
| `grc.geolocation.status` | enum | `compliant` | ZKP-verified geofence result |
| `grc.geolocation.region_id` | string | `US-EAST-1` | Broad compliance region (Reg-K) |
| `grc.geolocation.proof` | base64 | `eyJ...` | The actual ZKP proof for auditor verification |
| `grc.geolocation.sensor_type` | enum | `CAMARA_MNO` | Which sensor provided the location |

---

## 6. Enterprise Use Case: Private Wealth Gen-AI Advisory

### Scenario (Use Case 1 - Enterprise Customer)

A high-net-worth client uses the **Private Wealth Gen-AI Advisory** from their personal mobile device. The bank must prove to an EU regulator that the AI inference stayed within the EEA (**Reg-K** compliance), but cannot store raw GPS data (**GDPR** violation).

### The Privacy-Preserving Flow

1. **Client opens app** on personal iPhone/Android
2. **CAMARA API** verifies device location via MNO (carrier-level, not app-level)
3. **ZKP circuit** generates proof: "Device is within EEA boundary"
4. **SVID issued** with `grc.geolocation.status: compliant` and `grc.geolocation.region_id: EEA`
5. **AI inference executes** with verified geolocation claim
6. **Evidence Bundle** includes ZKP proof for auditor

**Result:** The bank proves Reg-K compliance without ever touching raw GPS coordinates.

---

## 7. The Evidence Bundle for Auditors

When an auditor requests geolocation compliance evidence:

```json
{
  "bundle_type": "GEOLOCATION_COMPLIANCE",
  "audit_window": {
    "start": "2026-01-20T00:00:00Z",
    "end": "2026-01-20T23:59:59Z"
  },
  "compliance_boundary": {
    "name": "EEA_REGULATION_K",
    "polygon_hash": "sha256:abc123..."
  },
  "sessions": [
    {
      "session_id": "sess-001",
      "svid": "spiffe://aegis.local/workload/private-wealth-advisory",
      "geolocation_claim": {
        "status": "compliant",
        "region_id": "EEA",
        "sensor_type": "CAMARA_MNO",
        "zkp_proof": "base64-noir-proof..."
      },
      "timestamp": "2026-01-20T14:00:00Z"
    }
  ],
  "aggregate_stats": {
    "total_sessions": 15847,
    "compliant_sessions": 15847,
    "non_compliant_sessions": 0
  },
  "signatures": {
    "aegis_geolocation_jws": "eyJhbGciOiJSUzI1NiIs..."
  }
}
```

### Auditor Verification Workflow

1. **Verify Boundary Definition:** Confirm the `polygon_hash` matches the official Reg-K boundary.
2. **Verify ZKP Proofs:** For each session (or sample), verify the ZKP proof against the boundary.
3. **Verify Hardware Attestation:** Confirm the session was on attested hardware via SVID.
4. **Aggregate Compliance:** Confirm all sessions in the audit window are compliant.

### Example: Policy Proof Generation & Verification

> [!NOTE]
> **Public Boundary Policy:** Unlike proprietary prompt logic, geolocation compliance boundaries (e.g., "EEA", "US-EAST") are defined by regulation—not trade secrets. Sharing the exact boundary polygon with auditors is a **reasonable default**.

#### Step 1: Enterprise Generates Policy Proof

The Enterprise defines the compliance boundary and generates a verifiable policy commitment:

```json
// POLICY DEFINITION (Public - shared with Auditor)
{
  "policy_name": "EEA_REGULATION_K_v2",
  "policy_version": "2026.1",
  "boundary_polygon": [
    {"lat": 71.185, "lon": -9.55},   // Norway (northwest)
    {"lat": 71.185, "lon": 31.59},   // Finland (northeast)
    {"lat": 34.80, "lon": 31.59},    // Cyprus (southeast)
    {"lat": 36.00, "lon": -9.55}     // Portugal (southwest)
  ],
  "policy_hash": "sha256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069"
}
```

The Keylime Agent Plugin generates ZKP proofs using this policy:

```
Enterprise Server (Keylime Agent Plugin)
═════════════════════════════════════════

1. Load Policy: EEA_REGULATION_K_v2
2. Receive TPM-signed GPS: (48.8566, 2.3522)  ← Paris
3. ZKP Circuit: point_in_polygon(48.8566, 2.3522, EEA_BOUNDARY) → TRUE
4. Generate Proof: π = Prove(coordinates, boundary, tpm_sig)
5. TPM Sign Output: output_sig = TPM_Sign(SHA256(π))
6. Emit SVID Claim: grc.geolocation.status = "compliant"
```

#### Step 2: Auditor Verifies Proof

The Auditor receives the Evidence Bundle and verifies independently:

```
Auditor Verification (Independent)
══════════════════════════════════

1. Retrieve Policy: Download EEA_REGULATION_K_v2 from regulatory registry
2. Verify Policy Hash: SHA256(boundary_polygon) == "sha256:7f83b..." ✓
3. Verify ZKP Proof: 
   - Load proof π from Evidence Bundle
   - Load public inputs: boundary_polygon, tpm_public_key, timestamp
   - Run Noir Verifier: Verify(π, public_inputs) → TRUE ✓
4. Verify TPM Output Signature:
   - Verify output_sig against Keylime-registered TPM public key ✓
5. Conclusion: "Session was on verified hardware within EEA boundary"
```

**Key Insight:** The Auditor never sees the precise GPS coordinates (48.8566, 2.3522). They only verify that:
- A valid TPM-signed coordinate existed (input integrity)
- That coordinate was inside the EEA polygon (compliance)
- The proof was generated on a specific Keylime-attested server (output integrity)

---

## 8. Regulatory Mapping

| Regulatory Need | AegisSovereignAI Implementation |
|-----------------|--------------------------------|
| **Reg-K (Data Residency)** | ZKP proves location within boundary without storing coordinates |
| **GDPR Art. 5 (Data Minimization)** | No raw GPS data ever leaves the device |
| **GDPR Art. 25 (Privacy by Design)** | Hardware-rooted ZKP is privacy-first architecture |
| **EU AI Act (Transparency)** | Auditor receives verifiable proof, not opaque assertions |

---

## 9. Integration with Layer 3 AI Governance

Geolocation verification is a **Layer 2 prerequisite** for Layer 3 AI Governance. The modular architecture:

```
┌─────────────────────────────────────────────────────────────┐
│  MODULAR EVIDENCE BUNDLE VERIFICATION                       │
└─────────────────────────────────────────────────────────────┘

  Stage 1: Environmental Trust (This Document)
  ═════════════════════════════════════════════
  ✓ Is this a genuine, untampered device?
  ✓ Is the device within the compliance boundary?
  ✓ Is the SVID bound to attested hardware?
                    │
                    ▼
  Stage 2: Content Trust (AI Governance)
  ═══════════════════════════════════════
  ✓ Did the system prompt contain required guardrails?
  ✓ Were user prompts scanned for injection attacks?
  ✓ Were AI outputs filtered for PII leakage?
  
  See: [Privacy-Preserving AI Governance](./auditor-privacy-preserving-ai-governance.md)
```

---

[Root README](../README.md) | [Auditor Guide](./auditor.md) | [Unified Identity Framework](../hybrid-cloud-poc/README-arch-sovereign-unified-identity.md) | [AI Governance (Layer 3)](./auditor-privacy-preserving-ai-governance.md)
