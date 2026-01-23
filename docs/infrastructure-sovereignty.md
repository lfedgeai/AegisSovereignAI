# Infrastructure Sovereignty: Layer 1 & Layer 2 Trust Primitives

> **For Technical Auditors & Architects:** This document covers the **Environmental Trust** foundations (Hardware + Identity + Location) that must be established before Layer 3 AI Governance can begin. For the AI-specific governance model (prompts, outputs, compliance proofs), see the **[Privacy-Preserving Deep-Dive](./auditor-privacy-preserving-deep-dive.md)**.

---

## 1. Overview: The Sovereign Anchor

Before auditing **what the AI is saying** (Layer 3), auditors must first verify **where the AI is running** and **on what hardware** (Layers 1 & 2). This separation is critical for large-scale deployments where infrastructure teams and AI governance teams operate independently.

| Layer | Trust Domain | Verification Question |
|-------|--------------|----------------------|
| **Layer 1: Infrastructure** | Hardware Trust | "Is this genuine, untampered silicon?" |
| **Layer 2: Identity** | Environmental Trust | "Is this workload running in an authorized location on an authorized device?" |
| **Layer 3: Governance** | Content Trust | "Did this AI follow the governance policy?" (See [Privacy-Preserving Deep-Dive](./auditor-privacy-preserving-deep-dive.md)) |

**The Modular Evidence Bundle:** When an auditor receives an Evidence Bundle, verification proceeds in stages:
- **Stage 1 (This Document):** "Is this a valid Aegis Sovereign Node?" → Verified via Layer 1/2 Attestation
- **Stage 2 ([Deep-Dive](./auditor-privacy-preserving-deep-dive.md)):** "Did this node follow the governance policy?" → Verified via Layer 3 ZKP

---

## 2. Layer 1: Hardware Trust (Silicon Attestation)

### Confidential Computing & TEEs

AegisSovereignAI integrates with multi-vendor hardware Trusted Execution Environments (TEEs):
- **Intel TDX** (Trust Domain Extensions)
- **AMD SEV** (Secure Encrypted Virtualization)
- **NVIDIA H100 TEEs** (Confidential Computing)

**The Guarantee:** Model weights and inference context remain encrypted in-use, shielded from privileged administrators.

### Integrity for Legacy/Edge (TPM 2.0 + Keylime)

On commodity hardware without TEE support, AegisSovereignAI uses:
- **Trusted Platform Module (TPM 2.0):** Hardware-rooted key storage and measurements
- **Keylime:** Remote attestation agent for continuous integrity verification
- **Integrity Measurement Architecture (IMA):** Runtime file integrity verification
- **Extended Verification Module (EVM):** Extended attribute integrity

**The Guarantee:** The software stack is verified as untampered before any AI workload executes.

### Hardware-Type Binding (Computational Determinism)

For quantitative risk management, AegisSovereignAI can restrict model execution to verified silicon types (e.g., NVIDIA H100 vs. A100).

**The Challenge (The "Silicon Lottery"):** Even at `temperature=0`, the same model produces different outputs on different GPU types due to floating-point math and parallel execution variations.

**The Solution:** Hardware attestation includes GPU type verification, ensuring regulated workloads produce reproducible results on consistent hardware. This supports **MRM** and **SR 11-7** compliance.

---

## 3. Layer 2: Identity & Location Trust

### Hardware-Rooted Workload Identity (SPIFFE/SPIRE + Keylime)

AegisSovereignAI binds SPIFFE/SPIRE workload identities to hardware credentials:
- The **SVID** (SPIFFE Verifiable Identity Document) is cryptographically fused with TPM attestation
- An agent cannot execute unless it is on a **verified, authorized machine**

**The Guarantee:** Workload identity cannot be replayed or spoofed—the token is bound to specific silicon.

### Privacy-Preserving Geofencing (Reg-K Compliance)

Before auditing AI logic, auditors must often verify **where** the data is being processed to comply with residency laws like **Regulation K** or **GDPR**.

**The Challenge:** Traditional GPS/IP-based geofencing creates PII liability by storing the user's precise location.

**The ZKP Solution:** A "Coordinate-in-Polygon" circuit.
1. **Private Input:** The node's precise GPS/cellular coordinates (verified by TPM-signed sensor data).
2. **Public Input:** The permitted geographic boundary (the "Green Zone" polygon).
3. **Proof:** The circuit mathematically proves the private coordinate is inside the public polygon without ever revealing the coordinate itself.

**Outcome:** The auditor sees a "Pass/Fail" cryptographic result tied to a hardware-rooted identity, satisfying residency requirements with zero privacy leakage.

### Autonomous Revocation

If a node's hardware state drifts (detected by Keylime), its SPIFFE/SPIRE identity is revoked in **real-time**, isolating the workload before lateral movement.

---

## 4. Data Ingestion Provenance (Track A)

Proving the integrity and origin of raw data before it enters the AI pipeline.

**Process:**
1. **Hardware Attestation:** Data is ingested through a FIDO/TPM-verified node.
2. **Provenance ZKP:** A circuit proves that the data was signed by a genuine hardware-rooted key associated with a specific authorized region, while **hiding the specific device UUID** or MSISDN.

**Outcome:** Proof of Data Integrity and Regional Provenance without creating a "Device Tracking" database.

### Compliant-Boundary Verification

Privacy-preserving proofs validate that ingested data was collected within a compliant geographic boundary (e.g., Reg-K) **without the Enterprise ever touching raw GPS coordinates** — transforming a privacy liability into a cryptographic compliance asset.

### Data Minimization Proof

Generates proofs validating that the dataset satisfies GDPR Data Minimization principles before entering the vector store.

---

## 5. The Layer 1/2 Evidence Bundle

When an auditor requests infrastructure attestation, they receive:

```json
{
  "attestation_type": "LAYER_1_2_INFRASTRUCTURE",
  "timestamp": "2026-01-20T14:00:00Z",
  "hardware": {
    "tee_type": "INTEL_TDX",
    "attestation_quote": "base64-remote-attestation-quote...",
    "gpu_type": "NVIDIA_H100",
    "tpm_pcr_values": {
      "PCR0": "sha256:...",
      "PCR7": "sha256:..."
    }
  },
  "identity": {
    "svid": "spiffe://aegis.local/workload/private-wealth-advisory",
    "keylime_status": "VERIFIED",
    "last_attestation": "2026-01-20T13:59:45Z"
  },
  "geofence": {
    "policy": "EEA_COMPLIANT",
    "zkp_proof": "base64-coordinate-in-polygon-proof...",
    "result": "WITHIN_BOUNDARY"
  },
  "signatures": {
    "aegis_infrastructure_jws": "eyJhbGciOiJSUzI1NiIs..."
  }
}
```

**Auditor Workflow (Stage 1):**
1. **Verify Hardware Attestation:** Confirm the TEE/TPM quote is valid and from approved silicon.
2. **Verify Identity Binding:** Confirm the SVID is bound to the attested hardware.
3. **Verify Geofence Proof:** Confirm the workload is within the compliant boundary.

Once Stage 1 passes, the auditor proceeds to **Stage 2** ([Layer 3 Governance Verification](./auditor-privacy-preserving-deep-dive.md)).

---

## 6. Regulatory Mapping (Layers 1 & 2)

| Regulatory Need | AegisSovereignAI Implementation |
|-----------------|--------------------------------|
| **EU AI Act (Cybersecurity Standards)** | Hardware-enforced isolation via TEEs |
| **NIST AI RMF (RESILIENT)** | TEE-based model/context shielding |
| **Reg-K (Data Residency)** | Privacy-preserving geofence proofs |
| **GDPR Art. 5 (Data Minimization)** | Provenance proofs without device tracking |
| **SR 11-7 (Reproducibility)** | Hardware-type binding for computational determinism |

---

[Root README](../README.md) | [Auditor Guide](./auditor.md) | [Privacy-Preserving Deep-Dive (Layer 3)](./auditor-privacy-preserving-deep-dive.md)
