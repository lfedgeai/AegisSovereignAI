# Auditor Guide: Verifying the Sovereign Trust Loop

AegisSovereignAI provides a cryptographically verifiable solution to the **"Accountability Gap"** in modern AI infrastructure. This guide provides auditors and risk officers with the technical framework required to prove compliance with global standards, including the **EU AI Act**, **NIST AI RMF**, and **Regulation K (Reg-K)**.

## 1. Why Auditors Need Attestation-Linked Proofs

Traditional IT security relies on **Infrastructure Blind Spots**—where an administrator or a compromised hypervisor can bypass governance controls. AegisSovereignAI eliminates these blind spots by anchoring all AI operations in **Silicon-Rooted Trust**.

Auditors use time-bound, attestation-linked proofs to:
- **Test Control Effectiveness**: Verify that claimed controls (attestation, residency, model integrity) worked at a concrete instant.
- **Solve the Residency vs. Privacy Deadlock**: Use **Zero-Knowledge Proofs (ZKPs)** to prove data residency and model compliance without ingesting or storing high-liability **Personally Identifiable Information (PII)**.
- **Establish Physical Provenance**: Prove that a specific decision was made on authorized, heterogeneous hardware (Intel TDX, AMD SEV, NVIDIA H100) and not on a spoofed or unauthorized platform.
- **Ensure Litigation Readiness**: Create an evidentiary chain suitable for regulatory audit, expert review, or courtroom discovery.

## 2. Regulatory & Standards Mapping

AegisSovereignAI evidence bundles map directly to the requirements of the **EU AI Act** and **NIST AI RMF**:

| Regulation/Standard | Control Objective | AegisSovereignAI Evidence |
| --- | --- | --- |
| **EU AI Act Art. 10** | Data & Governance | Verifiable system prompt circuits proving no PII leak or unauthorized logic. |
| **EU AI Act Art. 12** | Record-keeping | Cryptographically signed logs linked to hardware-rooted SVIDs. |
| **NIST AI RMF (GOVERN)** | Governance & Policy | Policy-as-Circuit enforcement via ZKP / Noir compilation. |
| **NIST AI RMF (RESILIENT)**| Security & Robustness | TEE-based (Intel TDX/AMD SEV) model weight and prompt isolation. |

## 3. The Evidence Chain: From Silicon to Report

The AegisSovereignAI **Sovereign Trust Loop** produces a minimal, portable proof package designed for ingestion into standard enterprise **SIEM/GRC (Security Information and Event Management / Governance, Risk, and Compliance)** platforms.

### Step 1: Hardware-Rooted Node Attestation
SPIRE issues a **SPIFFE Verifiable Identity Document (SVID)** only after a successful **Trusted Platform Module (TPM)** quote is verified by the Keylime verifier.
- **Evidence**: Signed TPM Quote + Node SVID.
- **Verification**: `notBefore ≤ T ≤ notAfter` (where T is the time of interaction).

### Step 2: Workload & Runtime Integrity
Keylime continuously monitors the software stack (IMA/EVM). If the node firmware or OS is compromised, the SVID is revoked by the **Autonomous Kill-Switch**.
- **Evidence**: Keylime integrity manifest.
- **Verification**: Node status = `ATTESTED` at time T.

### Step 3: Privacy-Preserving Compliance (ZKP)
For geofencing and model governance, AegisSovereignAI generates a Zero-Knowledge Proof (Noir circuit).
- **Evidence**: ZKP Proof + Public Verification Key.
- **Verification**: Mathematical proof validates residency/policy without revealing raw location or proprietary prompts.

## 4. Auditor Query Examples

### Scenario: High-Stakes Financial Advisory
*"Prove that at 15:00 IST, the AI Agent processing high-net-worth client data was running on an attested TEE-enabled node in North America."*
→ Ties to **Reg-K (Data Residency)** and **PCI DSS v4.0 Req. 10**.

**The Evidence Bundle:**
1. **Hardware Proof**: Intel TDX/AMD SEV attestation report signed by silicon provider.
2. **Identity Proof**: Node SVID with validity covering 15:00 IST.
3. **Residency Proof**: ZKP verifying the node was within a geofenced boundary without disclosing raw GPS coordinates.
4. **Conclusion**: Workload was executing in a cryptographically isolated environment on verified hardware in the approved region.

## 5. Implementation: The Compliance Pipeline

AegisSovereignAI enables an automated compliance pipeline:
1. **Traceability**: SVIDs are injected into every inter-service request.
2. **Collection**: Distributed logs are aggregated with cryptographic hashes.
3. **Narrative Generation**: An LLM-driven reporter maps raw evidence (hashes, SVIDs, TEE reports) into a human-readable narrative citing specific controls (e.g., EU AI Act §12).
4. **Portability**: Final reports and evidence bundles are exported as JSON/PDF for SIEM/GRC integration.

---

[Root README](../README.md) | [Threat Model](../hybrid-cloud-poc/THREAT-MODEL-runtime-perception-gap.md) | [IETF WIMSE Draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/)
