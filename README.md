# AegisSovereignAI: Trusted AI for the Distributed Enterprise

## Executive Summary
**AegisSovereignAI** is a unifying control plane for the distributed enterprise. It cryptographically fuses workload identities with silicon-level attestation and application-level governance to create a cohesive identity architecture that extends from the **Cloud Core to the Far Edge**.

By establishing a **Sovereign Trust Loop**, we move AI security from "Best-Effort" Zero-trust to **Privacy-First Verifiable Intelligence**. This enables cryptographic proof of compliance (data residency, prompt governance, output filtering) **without disclosing sensitive PII or proprietary logic**.

![AegisSovereignAI Architecture Summary](images/readme-arch-new-summary.svg)

## The Sovereign Trust Loop
AegisSovereignAI secures the entire AI lifecycle across three stages:

1.  **Stage 1: Verified Ingress**: Hardware-rooted attestation of the originating client device ensuring data provenance and **Regulation K (Reg-K)** compliance via privacy-preserving techniques (ZKP).
2.  **Stage 2: Trusted Processing**: Confidential Computing (TEEs) and Platform Integrity (Keylime) ensuring the AI workload is isolated from the cloud infrastructure.
3.  **Stage 3: Verifiable Egress**: Proof that AI insights are released only to identity-verified and geofenced endpoints.

👉 **[View the Technical PoC Guide](./hybrid-cloud-poc/README.md) for detailed setup and use cases.**

---

## Three-Layer Trust Architecture
AegisSovereignAI bridges the gap between Infrastructure Security and AI Governance.

### Layer 1: Infrastructure Security (Silicon)
*   **Confidential Computing**: Shielding model weights and context in-use (TDX, SEV, H100 TEE).
*   **Platform Integrity**: Using TPM 2.0 and Keylime to verify the device's software stack.

### Layer 2: Unified & Extensible Identity (Provable Bridge)
*   **Hardware-Bound SVIDs**: Binding SPIFFE identities to physical silicon and verifiable geolocation.
*   **Safe Harbor for BYOD**: Verifying unmanaged device integrity on-the-fly without managerial control.

### Layer 3: AI Governance (Verifiable Logic)
*   **Audit without Disclosure**: Using "Batch & Purge" proofs to verify prompt and output safety without storing high-liability raw data.
*   **Prompt/Model Integrity**: Cryptographic proof that mandatory safety guardrails are active.

---

## Interoperability & Standards
AegisSovereignAI is framework-agnostic, serving as a secure execution substrate for leading AI Agent orchestrators.

| Agent Framework | Complementary Value | How it Works |
| --- | --- | --- |
| **LangGraph** | **Just-in-Time Policy** | Automated Kill-Switch fused to silicon-rooted SVID. |
| **KAgentI (MCP)** | **Replay-Proof Auth** | Anchors MCP tool discovery to physical hardware. |
| **CSA AAGATE** | **NIST RMF Alignment** | Anchors DIDs to the physical TPM for policy enforcement. |

### Regulatory Alignment
| Feature Layer | EU AI Act | NIST AI RMF |
| --- | --- | --- |
| **Governance** | **Article 10**: Data & Governance integrity. | **GOVERN**: Privacy-preserving policy. |
| **Identity** | **Transparency Obligations**: Provable "Who/Where". | **MANAGE**: Workload-to-human mapping. |
| **Infrastructure** | **Cybersecurity Standards**: Hardware isolation. | **RESILIENT**: TEE-based shielding. |

---

## Quickstart & Resources

```bash
# Bootstrap the PoC environment
git clone https://github.com/lfedgeai/AegisSovereignAI.git
cd AegisSovereignAI/hybrid-cloud-poc
./install_prerequisites.sh
python ci_test_runner.py
```

### Specialized Deep-Dives
*   **[Auditor Guide](./docs/auditor.md)** - High-level evidence model and regulatory reporting.
*   **[Privacy-Preserving Geolocation](./docs/auditor-privacy-preserving-geolocation.md)** - ZKP-based Reg-K compliance.
*   **[AI Governance Lifecycle](./docs/auditor-privacy-preserving-ai-governance.md)** - Batch & Purge architecture.
*   **[Unified Identity Deep-Dive](./hybrid-cloud-poc/README-arch-sovereign-unified-identity.md)** - SPIRE/Keylime integration.
*   **[Threat Model](./hybrid-cloud-poc/THREAT-MODEL-unmanaged-device.md)** - Security analysis for unmanaged devices.
