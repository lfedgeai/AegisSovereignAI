# Auditor Guide: Verifying the Sovereign Trust Loop

> **For Auditors & Risk Officers:** This is the high-level guide to understanding AegisSovereignAI's attestation-linked evidence model. For a deep technical dive into **privacy-preserving techniques (e.g. ZKP)** circuits and the Five-Track architecture for the full AI lifecycle, see the **[Privacy-Preserving Deep-Dive for Technical Auditors](./auditor-privacy-preserving-deep-dive.md)**.

AegisSovereignAI provides a cryptographically verifiable solution to the **"Accountability Gap"** in modern AI infrastructure. This guide provides auditors and risk officers with the technical framework required to prove compliance with global standards, including the **EU AI Act**, **NIST AI RMF**, and **Regulation K (Reg-K)**.

## 1. Why Auditors Need Attestation-Linked Proofs

Traditional IT security relies on **Infrastructure Blind Spots**—where an administrator or a compromised hypervisor can bypass governance controls. AegisSovereignAI eliminates these blind spots by anchoring all AI operations in **Silicon-Rooted Trust**.

Auditors use time-bound, attestation-linked proofs to:
- **Test Control Effectiveness**: Verify that claimed controls (attestation, residency, model integrity) worked at a concrete instant.
- **Solve the Residency vs. Privacy Deadlock**: Use **privacy-preserving techniques (e.g. ZKP)** to prove data residency and model compliance without ingesting or storing high-liability **Personally Identifiable Information (PII)**.
- **Establish Physical Provenance**: Prove that a specific decision was made on authorized, heterogeneous hardware (Intel TDX, AMD SEV, NVIDIA H100) and not on a spoofed or unauthorized platform.
- **Ensure Litigation Readiness**: Create an evidentiary chain suitable for regulatory audit, expert review, or courtroom discovery.

## 2. Regulatory Control Mapping

For a Chief Risk Officer or a Regulatory Auditor, the value of AegisSovereignAI lies in its ability to provide **"Mathematical Proof of Compliance."** The following table maps technical architecture outputs to standard financial audit requirements.

### Table of Proofs: Cryptographic Evidence for Financial Compliance

| Regulatory Control Objective | AegisSovereignAI Technical Proof | Cryptographic Artifact / Output |
| --- | --- | --- |
| **Data Residency (Reg-K / GDPR):** Proof that PII processing is geographically restricted. | **Verifiable Geofence:** A hardware-rooted proof of location. | **privacy-preserving techniques (e.g. **ZKP**):** A "True/False" result validating the node is within a boundary without exposing precise location data. |
| **Data Provenance (NIST AI RMF):** Proof that training data is from genuine hardware sources. | **Ingestion Attestation:** Hardware-rooted identity for sensor/data nodes. | **Track A: Ingestion ZKP:** Proof of regional origin while masking specific device UUIDs. |
| **Data Quality (EU AI Act):** Proof that models were trained on clean, redacted data. | **Redaction Verification:** Automated dataset scanning and weight-binding. | **Track B: Training ZKP:** Proof that PII/forbidden patterns were excluded from the training set. |
| **Workload Integrity (OCC 2021-12):** Proof that AI models and logic have not been tampered with. | **IMA/EVM Runtime Attestation:** Continuous measurement of the software stack. | **TPM Quote:** A signed SHA-256 hash of the software state, verified against a "Golden Manifest" by Keylime. |
| **Prompt/Output Compliance:** Proof that AI interactions (Input/Output) were governed. | **Sovereign Prompt Verification:** Real-time filtering with Verifiable Batch & Purge. | **Tracks D & E: Inference ZKPs:** Proof of "Compliance-by-Design" for system/user prompts and AI outputs. |
| **Access Control (Least Privilege):** Proof that only authorized users on verified hardware can access AI. | **Blended SVID Identity:** Fuses user session (OIDC) with hardware state (TPM). | **SPIFFE SVID:** A short-lived X.509 certificate that is only issued if hardware integrity passes. |
| **Model Confidentiality (DORA):** Proof that weights/prompts are protected from infrastructure admins. | **TEE Evidence:** Proof of execution within a Trusted Execution Environment. | **Attestation Report (Intel TDX / NVIDIA H100):** Hardware-signed report proving the workload is isolated in encrypted memory. |
| **Audit Traceability:** Proof of "who, what, where, and how" for a specific AI decision. | **Sovereign Trust Loop Log:** An aggregated log of all verified identities and attestations. | **Exportable Evidence Bundle:** A JSON/JWS bundle compatible with SIEM/GRC tools (Splunk, Archer, etc.). |

## 3. Implementation Narrative for the Auditor

### 1. The Evidence Generation Flow

When an AI inference request is made, AegisSovereignAI performs a "Pre-Flight Check":

1.  **Ingestion/Provenance Verification:** Proving the data source is a genuine hardware device in an authorized region (Track A).
2.  **Training/Redaction Verification:** Proving the model was trained only on policy-compliant, redacted data (Track B).
3.  **Hardware Verification:** Keylime requests a **TPM Quote** to ensure the silicon is genuine and the OS is untampered.
4.  **Location Verification:** The node generates a **privacy-preserving proof (e.g. ZKP)** that its current hardware-measured location matches the "Green Zone" policy.
5.  **Inference Governance (Batch & Purge):** Generating proofs for system/user prompts and AI outputs while purging raw data (Tracks C/D/E).
6.  **Identity Fusion:** SPIRE issues a **Unified SVID** that cryptographically binds the verified hardware to the specific User Session.

### 2. Continuous Monitoring vs. Point-in-Time Audit

Traditional audits are "point-in-time." AegisSovereignAI enables **Continuous Compliance**:

*   **Autonomous Kill-Switch:** If a hardware sensor (Layer 1) detects a change in the environment (e.g., a lid opening or a debug port being accessed), the **Keylime-to-SPIRE link** immediately revokes the identity.
*   **Outcome:** The auditor sees a "Closed Loop" where violations are prevented in real-time rather than discovered months later during a manual review.

### 3. GRC & SIEM Integration

To fit into existing bank workflows, the **Evidence Bundle** is designed to be ingested by standard tools (Splunk, Archer, etc.).

*   **Format:** Standardized JSON-LD with JWS (JSON Web Signature) for non-repudiation.
*   **Mapping:** Each bundle includes tags for **NIST AI RMF** and **ISO/IEC 42001** to allow for automated report generation.

#### Sample Evidence Bundle (JSON Structure)

```json
{
  "evidence_id": "ev-9823-bk-2026",
  "timestamp": "2026-01-20T04:15:00Z",
  "control_mappings": ["NIST-AI-RMF-GOVERN-1.1", "EU-AI-ACT-ART-12"],
  "subject": {
    "spiffe_id": "spiffe://aegis.enterprise/workload/gen-ai-advisor",
    "hardware_id": "tpm-id-7728-intel-tdx"
  },
  "attestation": {
    "status": "VERIFIED",
    "verifier": "keylime-verifier-primary",
    "tpm_quote_signature": "base64-encoded-signature-hash",
    "ima_status": "MATCH"
  },
  "geofence": {
    "policy": "NORTH-AMERICA-GREEN-ZONE",
    "zkp_proof": "base64-noir-proof-artifact",
    "result": "PASSED"
  },
  "provenance": {
    "track": "A (Data Ingestion)",
    "region_proof": "base64-noir-proof-artifact",
    "hardware_fido_attestation": "VALID"
  },
  "training_redaction": {
    "track": "B (Model Training)",
    "policy": "PII-REDACTION-STANDARD-V2",
    "proof": "base64-noir-proof-artifact"
  },
  "inference_governance": {
    "tracks": ["C", "D", "E"],
    "system_prompt_proof": "OK",
    "user_prompt_batch_id": "batch-1029",
    "output_safety_proof": "OK"
  },
  "signatures": [
    {
      "signer": "aegis-control-plane",
      "jws": "eyJhbGciOiJSUzI1NiIsImtpZCI6In..."
    }
  ]
}
```

---

[Root README](../README.md) | [Threat Model](../hybrid-cloud-poc/THREAT-MODEL-runtime-perception-gap.md) | [IETF WIMSE Draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/)
