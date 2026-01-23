# AegisSovereignAI: Trusted AI for the Distributed Enterprise

## Executive Summary
In a Distributed Enterprise, Infrastructure Security (Layer 1 in Figure 1) and AI Governance (Layer 3 in Figure 1) are often loosely coupled across the spectrum from **centralized clouds to the far edge**. This fragmentation results in a dangerous **"Accountability Gap"** where workload/user identities are easily spoofed, compliance creates massive **Personally Identifiable Information (PII)** liability, and compromised infrastructure — whether in a hyperscale data center or a remote branch office — can feed fake data to applications undetected. 

**AegisSovereignAI** bridges this gap by serving as a unifying control plane for the comprehensive distributed footprint. Through a **Unified and Extensible Identity (Layer 2 in Figure 1)** framework, it cryptographically fuses workloads/user identities using silicon-level attestation with application-level governance while preserving privacy to create a single, cohesive identity architecture that extends from the **Cloud Core to the Far Edge**.

This transforms AI security from "Best-Effort" Zero-trust to **Privacy-First Verifiable Intelligence** — enabling cryptographic proof of compliance (data residency, prompt governance, output filtering) **without disclosing sensitive PII or proprietary logic**. This ensures that sensitive data (financial, medical, etc.) is processed only when the hardware, the location, and the workload/user identity are simultaneously verified, providing end-to-end sovereignty across the entire enterprise estate.

![Figure 1: AegisSovereignAI Architecture Summary](images/readme-arch-new-summary.svg)
*Figure 1: AegisSovereignAI Architecture Summary - Bridging Infrastructure, Identity, and Governance.*

**See the [Unified Identity Hybrid Cloud Proof of Concept (PoC) Guide](./hybrid-cloud-poc/README.md) for concrete use cases and detailed setup instructions.**

## Enterprise Sovereign Use Cases (Focus: Financial Services)

### 1. The Enterprise Customer (Retail/Private Banking End-Consumer)
*   **Core Use Case:** **Private Wealth Gen-AI Advisory (Unmanaged Devices).** Providing high-net-worth clients with AI-driven portfolio insights on their personal, unmanaged devices while using their physical location for **Regulation K (Reg-K)** compliance without disclosing precise location to the AI service. 

### 2. The Enterprise Employee (Branch Relationship Manager)
*   **Core Use Case:** **Secure Remote Branch Operations.** Allowing Relationship Managers to access sensitive PII from "Green Zone" servers on managed hardware, whether at a branch or a verified remote location.

### 3. The Enterprise Tenant (Line-of-Business Owner aka LOB)
*   **Core Use Case:** **Secure Sandboxing for LOBs.** Enabling enterprise tenants (e.g., Mortgage and Credit Card) to share the same physical Sovereign Cloud while ensuring total cryptographic isolation of their respective workloads, including AI models and data. From a tenant AI service perspective: data ingestion pipelines must prove PII was redacted and provenance verified before entering the tenant's vector store; the AI system prompt must contain mandatory safety guardrails (e.g., "never disclose account numbers"); user prompts must be scanned for injection attacks (e.g. "ignore previous instructions"); and AI outputs must be verified for PII leakage (hallucinations) before delivery.

### 4. The Regulator (e.g., Office of the Comptroller of the Currency (OCC), European Central Bank (ECB), Securities and Exchange Commission (SEC))
*   **Core Use Case:** **Automated Regulatory Audit.** While traditional audit models provide visibility through coarse data logging, applying this to AI creates a **Privacy Liability Paradox**: the more granular the audit (e.g., logging raw prompts/outputs), the higher the ingestion risk of sensitive PII and proprietary secrets. The **Regulator** requires real-time, cryptographically verifiable proof-of-compliance—demonstrating that: (1) all data ingested into AI systems (training data, Retrieval-Augmented Generation / RAG vector stores) was properly redacted and provenance-verified; (2) every AI interaction across the Enterprise strictly followed mandatory policy (trusted hardware, untampered models, and data residency); all without the liability of raw data ingestion or the exposure of proprietary prompt logic. This hardware-rooted provenance supports the reproducibility and documentation principles of the **Model Risk Management (MRM)** regulatory framework and **Federal Reserve/OCC Supervisory Letter SR 11-7** (Interagency Guidance on Model Risk Management).

---

## Technical Challenges for Addressing Use Cases

To address the above use cases, we must solve the unique technical problems below. Note that the below technical problems are not unique to AI or Financial Services but are especially critical for the security, privacy, and compliance of the above use cases. 

### 1. The Fragility of Identity & Geofencing
Traditional security relies on **bearer tokens** and **IP-based geofencing**, which are fundamentally non-binding and easily spoofed.
* **Replay Attacks:** Standard tokens function like a physical key; if a malicious actor intercepts a token, they can replay it to impersonate a legitimate workload (e.g., an AI agent).
* **VPN-based Spoofing:** Commonly used IP-based location checks are trivial to bypass using VPNs, allowing remote attackers to appear within "Green Zones."
    * **Example (Use Case 2 - Enterprise Employee):** A Relationship Manager attempts to access the "Green Zone" server from an unauthorized jurisdiction via a residential VPN. Traditional IP-checks fail to detect the spoofed location.

### 2. The Residency vs. Privacy Deadlock
Regulators require proof of data residency (e.g., **Regulation K aka Reg-K**), but traditional geofencing relies on ingesting high-resolution location data (GPS, Mobile Network, etc.), creating massive PII liability under privacy regulations (e.g., **General Data Protection Regulation (GDPR)**). Enterprises are often forced to choose between non-compliance or privacy violation.
* **Example (Use Case 1 - Enterprise Customer):** A high-net-worth client uses the Private Wealth Gen-AI Advisory from their personal mobile device. The bank must prove to an EU regulator that the AI inference stayed within the EEA (**Reg-K** compliance), but doing so requires ingesting or storing raw GPS data from the client's device — a GDPR violation.

### 3. Infrastructure Compromise
Modern AI workloads are vulnerable to **infrastructure compromise**, where a compromised OS or Hypervisor feeds, for example, fake location data to the application (e.g., via Frida hooks), tricking compliance logic while the device is in an unauthorized jurisdiction.
* **Example (Use Case 2 - Enterprise Employee):** A compromised branch server's hypervisor feeds fake "within Green Zone" location data to the AI workload via Frida hooks, allowing a Relationship Manager to appear compliant while accessing sensitive PII from an unauthorized jurisdiction.

### 4. The "Silicon Lottery": Hardware-Induced Drift & Computational Determinism
AI prompt response drift can be influenced by the type of hardware. Response can vary based on randomness setting (e.g., temperature). Even when randomness is fully disabled (e.g., `temperature=0`), the same model can produce different outputs on different hardware types (e.g., NVIDIA A100 vs H100) due to floating-point math and parallel execution differences. For quantitative risk management, **Computational Determinism** — ensuring that the same model on the same hardware type produces consistent results — is essential. Enterprises require the ability to restrict and verify hardware types to ensure deterministic outcomes for regulated workloads.
* **Example (Use Case 3 - Enterprise Tenant):** The Mortgage LOB's credit risk model produces different risk scores when run on A100 vs H100 GPUs due to floating-point variations. Traditional infrastructure management cannot guarantee which hardware type executed a given inference, making regulatory reproducibility impossible.

### 5. The Black-Box Governance Gap: Integrity & Data Liability
AI models are non-deterministic, making them difficult to audit. There is no cryptographic proof that a specific decision was made using untampered AI models/prompts without disclosing sensitive data. This is further complicated by **Prompt Injection** (malicious instructions) and **Hallucinations** (unintended PII leakage).
* **The "Audit Paradox":** Traditional logging for compliance creates massive PII/IP liability, but *not* logging prevents forensics and "Effective Challenge."
* **Example (Use Case 3 & 4 - Enterprise Tenant & Regulator):** An OCC auditor needs to verify that the Credit Card LOB's AI agent didn't use prohibited demographic data for credit scoring. Under current methods, the bank must disclose raw prompts to the auditor — revealing the LOB's proprietary scoring logic and customer PII — creating significant liability.

### 6. Bring Your Own Device (BYOD) Security Gaps
BYOD devices are unmanaged and unverified, making them a significant security risk for data leakage and unauthorized access.
* **Example (Use Case 1 - Enterprise Customer):** A high-net-worth client accesses the Private Wealth Gen-AI Advisory from their personal iPad. The device may be jailbroken or compromised without the bank's knowledge, creating an undetectable data leakage vector for sensitive portfolio information.

### 7. Edge Security Gaps
Edge nodes are often in untrusted physical locations, making them vulnerable to physical tampering and unauthorized environment modification.
* **Example (Use Case 2 - Enterprise Employee):** A rural bank branch server used by Relationship Managers is physically compromised or stolen. Traditional software-based security cannot detect hardware tampering, allowing attackers to extract AI model weights and sensitive customer PII.

---

## The Three-Layer Trust Architecture: Fusing Silicon, Identity, and Governance

**AegisSovereignAI** bridges Infrastructure Security (Layer 1 in Figure 2) and AI Governance (Layer 3 in Figure 2) by serving as a unifying control plane. Through a **Unified and Extensible Identity (Layer 2 in Figure 2)** framework, it cryptographically fuses workloads/user identities using silicon-level attestation with application-level governance while preserving privacy to create a single, cohesive identity architecture.

### Layer 1: Infrastructure Security (The Confidentiality Upgrade Path)

* **Confidential Computing (CC) & Trusted Execution Environments (TEEs):** Integrates with multi-vendor hardware (e.g., **Intel TDX**, **AMD SEV**, and **NVIDIA H100 TEEs**) to ensure model weights and context remain encrypted in-use, shielding them from privileged admins.
* **Integrity for Legacy/Edge:** On commodity hardware, AegisSovereignAI uses **Keylime** and **Trusted Platform Module (TPM 2.0)** to verify the software stack's **Integrity** (via **Integrity Measurement Architecture (IMA)** and **Extended Verification Module (EVM)**). 
* **Hardware-Type Binding for Computational Determinism:** Restricts model execution to verified silicon types (e.g., NVIDIA H100 vs. A100). This ensures that regulated AI workloads produce consistent, non-drifted outputs by mathematically guaranteeing the specific execution hardware, addressing the "Silicon Lottery" risk. This hardware-rooted provenance supports the reproducibility and documentation principles of **MRM** and **SR 11-7** compliance.

### Layer 2: Unified and Extensible Identity (The Provable Bridge)

* **Hardware-rooted geo-fenced workload Identity (SPIFFE/SPIRE, Keylime):** Binds SPIFFE/SPIRE workload identities to hardware credentials (TPM). An agent cannot execute unless it is on a verified, authorized machine in an authorized geolocation boundary. **Privacy-preserving techniques** (e.g., Zero-Knowledge Proofs / ZKPs) are used to prove location compliance with regulations without the Enterprise ever having to ingest or store sensitive precise location data.
* **Safe Harbor for Bring Your Own Device (BYOD):** Securely extend Agentic workflows to unmanaged customer devices by verifying **Silicon Integrity** on the fly instead of **Enterprise Device Ownership**. This creates a regulatory **Safe Harbor** for the Enterprise, proving that data only touched verified hardware without the liability of managing the device itself. 
* **Combined Human User, Workload, and Device Identity:** Combine human user sessions with BYOD/Enterprise device workload (e.g., mobile banking application) identities to ensure accountability in multi-agent graphs.
* **Autonomous Revocation:** If a node's hardware state drifts (detected by Keylime), its SPIFFE/SPIRE identity is revoked in **real-time**, isolating the agent before lateral movement.

### Layer 3: AI Governance (Verifiable Logic & Privacy)

*   **Audit without Disclosure:** Privacy-Preserving Compliance. AegisSovereignAI closes the **Sovereign Trust Loop** by solving the "Black Box" audit problem using **privacy-preserving techniques** across the complete AI lifecycle: **Training Data Ingestion → Inference Data Input → Model Inference System Prompt → Inference Data Output**. The Enterprise can provide cryptographically verifiable proof of compliance to regulators (e.g., **OCC** or **ECB**) without revealing proprietary prompt logic or sensitive PII.
    *   **Privacy-Preserving Data Ingestion:**
        *   **Confidential Transformation:** Raw data is ingested into Confidential Enclaves (Intel TDX/AMD SEV). Data is masked and redacted while encrypted in-use, shielded from infrastructure admins.
        *   **Hardware-Rooted Provenance:** Uses Fast Identity Online (FIDO)-based attestation to bind data to verified silicon, proving origin is genuine without ingesting persistent hardware identifiers.
        *   **Compliant-Boundary Verification:** Privacy-preserving proofs validate that ingested data was collected within a compliant geographic boundary (e.g., Reg-K) **without the Enterprise ever touching raw GPS coordinates** — transforming a privacy liability into a cryptographic compliance asset.
        *   **Data Minimization Proof:** Generates proofs validating that the dataset satisfies GDPR Data Minimization before entering the vector store.
    *   **System Prompt Integrity (Pre-Computed):** At deployment, we generate a permanent cryptographic proof that the AI System Prompt includes mandatory safety guardrails (e.g., SSN redaction) and excludes unauthorized directives. This ensures "Compliance-by-Design" without exposing the proprietary prompt text.
    *   **User Prompt Compliance (Batch & Purge):** User interactions are processed in real-time while a background process generates aggregated batch proofs. These proofs verify that no user prompts in a given window contained "jailbreak" commands or PII. Once the batch proof is successfully anchored to the enterprise audit log, the raw, high-liability prompts are purged from the system, permanently eliminating PII storage risk.
    *   **AI Output Filtering (Batch & Purge):** AI model outputs are verified through real-time Data Loss Prevention (DLP) scanning and content safety checks before delivery. Batch proofs demonstrate that all outputs were properly filtered to prevent hallucinated PII leakage (e.g., fabricated SSNs). Raw outputs are purged after proof generation, ensuring zero retention of AI-generated sensitive data. See the [Privacy-Preserving Deep-Dive](./docs/auditor-privacy-preserving-deep-dive.md) for the complete three-track verification model.
    *   **Effective Challenge Enablement (SR 11-7):** Provides cryptographically-verifiable **independent evidence** for model validators: proof of execution hardware, data provenance, and governance policy adherence. This enables "Effective Challenge" of third-party (vendor) AI models even when source code access is restricted—validators can verify the *execution environment* and *compliance state* without needing to inspect proprietary model internals.

![Figure 2: AegisSovereignAI Detailed Three-Layer Architecture](images/readme-arch-new.svg)
*Figure 2: AegisSovereignAI Detailed Three-Layer Architecture - The Sovereign Trust Loop.*

## Sovereign Value Realization for the above-mentioned Enterprise Use Cases

The following demonstrates the business value delivered by our three-layer trust model for each of the above-mentioned Enterprise Use Cases.

### 1. The Enterprise Customer
*   **Sovereign Value:** **Radical Privacy.** Users are verified as compliant (e.g., "In the US" or "In a Branch") via **privacy-preserving techniques**, ensuring the Enterprise meets regulatory metrics (**Reg-K**) without the privacy liability of storing raw customer location data. Additionally, every interaction is cryptographically proven to have mandatory PII redaction active on both the system prompt before any customer interaction occurs and the AI output before delivery.

### 2. The Enterprise Employee
*   **Sovereign Value:** **Frictionless Security.** Instead of manual VPNs or vulnerable passwords, the Hardware Integrity of their device (TPM/Keylime) automatically proves it is untampered and policy-compliant for workload execution on the employee's device.

### 3. The Enterprise Tenant
*   **Sovereign Value:** **Multi-Tenant Isolation.** Trust is established via cryptographically verifiable hardware-rooted Workload Identity rather than IP-based location.

### 4. The Regulator (e.g., Office of the Comptroller of the Currency (OCC), European Central Bank (ECB), Securities and Exchange Commission (SEC))
*   **Sovereign Value:** **Compliance without Liability.** By using **privacy-preserving techniques**, the Enterprise can prove regional residency to auditors without ingesting high-liability customer location data. They can also prove end-to-end AI integrity — e.g., ingested training data was properly redacted and provenance-verified; system prompts were governed, user prompts were safe, and AI outputs were filtered for hallucinations — without disclosing proprietary logic. These proofs are **exportable and compatible with standard Security Information and Event Management (SIEM) / Governance, Risk, and Compliance (GRC) tools** (e.g., Open Cybersecurity Schema Framework / OCSF), allowing for automated, continuous auditing within existing enterprise Security Operations Center (SOC) workflows.

## Regulatory & Standards Mapping
The AegisSovereignAI architecture provides a direct implementation path for global AI safety and governance frameworks:

| Feature Layer | EU AI Act Alignment | NIST AI RMF Alignment |
| --- | --- | --- |
| **Layer 3: Governance** | **Article 10 (Data & Governance):** Ensures training data/prompt integrity without PII exposure. | **Governance (GOVERN):** Transparent, documented privacy-preserving policy enforcement. |
| **Layer 2: Identity** | **Transparency Obligations:** Cryptographic proof of "Who" and "Where" without PII exposure. | **Accountability (MANAGE):** Precise workload/human identity mapping. |
| **Layer 1: Infrastructure** | **Cybersecurity Standards:** hardware-enforced isolation and TEE-based confidentiality. | **Secure (RESILIENT):** TEE-based model/context shielding from privileged admins. |

---

## Interoperability: The Sovereign Fabric for AI Agent Frameworks

AegisSovereignAI is designed to be framework-agnostic, serving as a secure execution substrate for leading AI Agent orchestrators. While tools like LangGraph and KAgentI manage the reasoning logic and multi-step workflows, AegisSovereignAI provides the **Hardware-Rooted Trust** and **Data Governance** required to move these agents from experimental PoCs to production-ready assets in regulated environments.

| Agent Framework | Complementary Value of AegisSovereignAI | How AegisSovereignAI Accomplishes This |
| --- | --- | --- |
| **LangGraph** | **Just-in-Time Policy Enforcement:** Prevents agentic drift or PII leakage across complex, multi-step workflows. | **Automated Kill-Switch (Hardware-Triggered):** Fuses the agent session with a silicon-rooted SVID (SPIFFE Verifiable Identity Document) (Layer 2). Session inputs and outputs are verified via privacy-preserving "Batch & Purge" (Layer 3) before final delivery — proofs are generated over the complete session, not per-step. Unlike software-level policies, this cannot be bypassed if the OS is compromised. |
| **KAgentI** | **Replay-Proof Agent Authorization:** Ensures each agent invocation is bound to verified hardware and privacy-preserving geolocation, preventing token replay and impersonation and sensitive data exfiltration attacks. | **Hardware-Rooted SVID:** Extends KAgentI's native SPIRE support by binding SVIDs to TPM-attested device credentials and privacy-preserving geolocation (Layer 2). This ensures the agent identity cannot be replayed or spoofed — the token is cryptographically bound to specific silicon and verified location while preserving privacy, not just a valid service principal. |

## Technical & Auditor Resources

*   **[Auditor Guide](./docs/auditor.md)** - High-level overview of the attestation-linked evidence model covering the full AI lifecycle (Ingestion, Training, and Inference), verifiable geofencing (Reg-K), and identity binding. Includes the complete Evidence Bundle structure for regulatory reporting.
*   **[Privacy-Preserving Geolocation (Layer 2)](./docs/auditor-privacy-preserving-geolocation.md)** - Technical deep-dive on **privacy-preserving geofencing** for Reg-K/GDPR compliance, including ZKP vs. other PETs comparison, multi-sensor fusion, and SVID geolocation claims.
*   **[Privacy-Preserving AI Governance (Layer 3)](./docs/auditor-privacy-preserving-ai-governance.md)** - Technical walkthrough of the **Four-Track Layer 3 Governance Lifecycle** (Training, System Prompt, User Prompt, Output), Batch & Purge architecture, and modular Evidence Bundle verification.
*   **[Threat Model: Unmanaged Device Security](./hybrid-cloud-poc/THREAT-MODEL-unmanaged-device.md)** - Analysis of **Infrastructure Blind Spots** on **BYOD/Unmanaged Devices**, detailing how AegisSovereignAI prevents location spoofing via hardware-rooted sensor fusion.
*   **[Unified Identity Deep-Dive](./hybrid-cloud-poc/README-arch-sovereign-unified-identity.md)** - Detailed technical architecture of the SPIRE/Keylime identity fusion model.
*   **[IETF WIMSE Draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/)** - Our contribution to standardizing verifiable geo-fences in multi-system environments.

## Quickstart

```bash
# Clone and bootstrap the PoC environment
git clone https://github.com/lfedgeai/AegisSovereignAI.git
cd AegisSovereignAI/hybrid-cloud-poc
./install_prerequisites.sh
python ci_test_runner.py
```

See the [Unified Identity Hybrid Cloud PoC Guide](./hybrid-cloud-poc/README.md) for detailed setup instructions.
