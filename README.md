# AegisSovereignAI: Trusted AI for the Distributed Enterprise

## Executive Summary
Traditionally Layer 1 (Infrastructure Security) and Layer 3 (AI Governance) are loosely coupled. This fragmentation results in a dangerous **"Accountability Gap"** where identities are easily spoofed, compliance creates massive **Personally Identifiable Information (PII)** liability, and compromised infrastructure can feed fake data to applications undetected. 

**AegisSovereignAI** bridges this gap by serving as a unifying control plane. Through a **Layer 2 Unified and Extensible Identity** framework, we cryptographically fuse silicon-level attestation with application-level governance—binding hardware integrity to both workloads and end-users while preserving privacy to create a single, cohesive architecture.

This transforms AI security from "Best-Effort" Zero-trust to **Privacy-First Verifiable Intelligence**. **This ensures that sensitive financial data only moves when the hardware, the location, and the user identity are simultaneously verified.**

![AegisSovereignAI Architecture Summary](images/readme-arch-new-summary.svg)

### Quick Links for Architects & PMs
*   **[Hybrid Cloud PoC](./hybrid-cloud-poc/README.md):** Real-time Revocation & **SPIFFE Verifiable Identity Document (SVID)** binding logic.
*   **[Threat Model](./hybrid-cloud-poc/THREAT-MODEL-runtime-perception-gap.md):** Analysis of Runtime Localitary Spoofing.
*   **[Unified Identity Deep-Dive](./hybrid-cloud-poc/README-arch-sovereign-unified-identity.md):** Blended Identity & **Workload Identity in Multi-System Environments (WIMSE)** integration.

## Enterprise Sovereign Scenarios: High-Stakes Challenges (Focus: Financial Services)

### 1. The Enterprise Customer (Retail/Private Banking End-Consumer)
*   **Core Use Case:** **Private Wealth Gen-AI Advisory (Unmanaged Devices).** Providing high-net-worth clients with AI-driven portfolio insights on their personal, unmanaged devices while guaranteeing that their physical location and identity are never leaked to the public cloud.
*   **Target Requirement:** Private interactions with Gen-AI advisors without sacrificing civil liberties or location history.

### 2. The Enterprise Employee (Branch Relationship Manager)
*   **Core Use Case:** **Secure Remote Branch Operations.** Allowing Relationship Managers to access sensitive PII from "Green Zone" servers on managed hardware, whether at a branch or a verified remote location.
*   **Target Requirement:** Frictionless access to sensitive client PII on-site for analysis or loan processing using managed laptops or branch servers.

### 3. The Enterprise Tenant (Line-of-Business Owner)
*   **Core Use Case:** **Regulatory Sandboxing for LOBs.** Enabling the Mortgage and Credit Card divisions to share the same physical Sovereign Cloud while ensuring total cryptographic isolation of their respective AI models and data.
*   **Target Requirement:** Guarantee that sensitive workloads are isolated even when sharing Sovereign Cloud infrastructure.

### 4. The Enterprise Stakeholder (Chief Risk/Sovereignty Officer)
*   **Core Use Case:** **Automated Regulatory Audit.** Providing a real-time, mathematical proof-of-compliance for regulators (**Office of the Comptroller of the Currency (OCC)** and **European Central Bank (ECB)**), demonstrating that every AI interaction—across all retail devices, employee hardware, and Data Center Infrastructure—was verified by hardware, uses trusted/untampered AI models and system prompts, and compliant with data residency laws.
*   **Target Requirement:** Compliance without disclosing sensitive data such as location history or sensitive AI model system prompts.

## The Accountability Gap: Five Dimensions of Failure

To address the above use cases, we must solve for the specific technical problems that traditional IT security cannot mitigate. Note that the below technical problems are not unique to AI or Financial Services. 

### 1. The Fragility of Identity & Geofencing
Traditional security relies on **bearer tokens** and **IP-based geofencing**, which are fundamentally non-binding and easily spoofed.
* **Replay Attacks:** Standard tokens function like a physical key; if a malicious actor intercepts a token, they can replay it to impersonate a legitimate workload (e.g., an AI agent).
* **VPN-based Spoofing:** Commonly used IP-based location checks are trivial to bypass using VPNs, allowing remote attackers to appear within "Green Zones."

### 2. The Residency vs. Privacy Deadlock
Regulators require proof of data residency (**Regulation K / Reg-K**), but traditional geofencing relies on ingesting high-resolution location data (GPS, Mobile Network, etc.), creating massive PII liability under the **General Data Protection Regulation (GDPR)**. Enterprises are often forced to choose between non-compliance or privacy violation.

### 3. Infrastructure Compromise
Modern AI workloads are vulnerable to **infrastructure compromise**—where a compromised OS or Hypervisor feeds fake sensor/location data to the application (e.g., via Frida hooks), tricking compliance logic while the device is in an unauthorized jurisdiction.

### 4. The "Silicon Lottery": Hardware-Induced Drift
AI prompt response drift is physically anchored to hardware. Even at `temperature=0`, a model running on an NVIDIA A100 can produce different numerical results than on an H100 due to non-associative math and thread-timing variations. Without **Physical Provenance**, there is no way to verify if a decision diverted due to unauthorized hardware migration.

### 5. The Black-Box Governance Gap
AI models are non-deterministic, making them difficult to audit. There is no cryptographic proof that a specific decision was made using trusted/untampered AI models/system prompts without disclosing sensitive data such as AI model system prompts.

## The Three-Layer Trust Architecture

AegisSovereignAI acts as the unifying control plane that cryptographically binds silicon-level attestation to application-level governance. Traditionally Layer 1 and Layer 3 are loosely coupled.  AegisSovereignAI unifies these layers into a single, cohesive architecture through the use of Layer 2 unified and extensible identity which binds the silicon-level attestation to workloads and end users and thus to the application-level governance.

### Layer 1: Infrastructure Security (The Confidentiality Upgrade Path)

* **Confidential Computing (CC) & Trusted Execution Environments (TEEs):** Integrates with **Intel TDX** and **NVIDIA H100 TEEs** to ensure model weights and context remain encrypted in-use, shielding them from privileged admins.
* **Integrity for Legacy/Edge:** On commodity hardware, AegisSovereignAI uses **Keylime** and **Trusted Platform Module (TPM 2.0)** to verify the software stack's **Integrity** (via **Integrity Measurement Architecture (IMA)** and **Extended Verification Module (EVM)**). 

### Layer 2: Unified and Extensible Identity (The Provable Bridge)

* **Hardware-rooted geo-fenced workload Identity (SPIRE/Keylime):** Binds SPIRE workload identities to hardware credentials (TPM). An agent cannot execute unless it is on a verified, authorized machine in an authorized geolocation location boundary. Privacy-preserving location proofs (e.g. Zero-Knowledge Proofs aka ZKPs) are used to prove compliance with regulations without the Enterprise ever having to ingest or store sensitive data.
* **Safe Harbor for Bring Your Own Device (BYOD):** Securely extend Agentic workflows to unmanaged customer devices by verifying **Silicon Integrity** instead of **Enterprise Device Ownership**.
* **Blended Identities:** Fuses human user sessions with workload identities to ensure **Just-in-Time Agency** and accountability in multi-agent graphs.
* **Autonomous Revocation:** If a node's hardware state drifts (detected by Keylime), its SPIRE identity is revoked in real-time, isolating the agent before lateral movement.
See the [Hybrid Cloud PoC](./hybrid-cloud-poc/README.md) for details.

### Layer 3: AI Governance (Verifiable Logic & Privacy)

* **Audit without Disclosure:** By using privacy-preserving proofs of AI model system prompt critical keyword inclusion and exclusion, the Risk Officer can prove compliance with regulations without the Enterprise ever having to ingest or store sensitive data.

![AegisSovereignAI Architecture](images/readme-arch-new.svg)

## Sovereign Value Realization: The Outcome of the Architecture

The following scenarios demonstrate the business value delivered by our three-layer trust model.

### 1. The Enterprise Customer
*   **Sovereign Value:** **Radical Privacy.** Users are verified as compliant (e.g., "In the US" or "In a Branch") via privacy-preserving location proofs (ZKP etc.), ensuring the Enterprise meets regulatory metrics (Reg-K) without the privacy liability of storing raw customer movement data.

### 2. The Enterprise Employee
*   **Sovereign Value:** **Frictionless Compliance.** Instead of manual VPNs or vulnerable passwords, the Hardware Integrity of their device (TPM/Keylime) automatically proves it is untampered and policy-compliant. If the device firmware is compromised, access is revoked cryptographically at the hardware layer.

### 3. The Enterprise Tenant
*   **Sovereign Value:** **Multi-Tenant Isolation.** Trust is established via cryptographically verifiable Workload Identity rather than network location. This provides hardware-enforced isolation between business units, even on shared silicon.

### 4. The Enterprise Stakeholder
*   **Sovereign Value:** **Compliance without Liability.** By using privacy-preserving location proofs and privacy-preserving AI model system prompt critical keyword inclusion and exclusion, the Risk Officer can prove regional residency to regulators without the Enterprise ever having to ingest or store high-resolution, high-liability customer location data or disclose PII in system prompts.

## The Sovereign Supply Chain: End-to-End Trust

AegisSovereignAI applies its three-layer architecture across the entire AI lifecycle.

| AI Lifecycle Stage | Layer 1: Infrastructure | Layer 2: Identity | Layer 3: Governance |
| --- | --- | --- | --- |
| **Data Ingestion** | Secure enclaves protect raw PII during ingestion. | **Fast Identity Online (FIDO)** ensures sensor hardware is genuine. | **Privacy-preserving techniques (ZKP etc.)** ensures data provenance without disclosure. |
| **Model Training** | **Multi-Vendor TEEs (Intel TDX, AMD SEV, NVIDIA H100)**—protects weights from privileged admin snooping. | Sigstore-signed datasets ensure data integrity. | **Fairness Auditing** via privacy-preserving circuits. |
| **Model Inference** | **Silicon-Enforced Privacy (NVIDIA H100, AMD MI300, ARM Realm)**—encrypts prompts and results in-use. | **Unified SVID** binds inference to verified silicon. | **Privacy-preserving techniques (ZKP etc.)** ensures execution matched policy. |

## Addressing AI Security Standards Gaps
Current AI security standards frameworks provide the "What" (the objective) but fail to provide the "How" (architecture and implementation) for high-stakes AI environments.

| Need | **Cloud Security Alliance (CSA)** / **National Institute of Standards and Technology (NIST)** Guidance | AegisSovereignAI Execution |
| --- | --- | --- |
| **Residency Proof** | "Use geofencing for data residency." | **Privacy-Preserving (ZKP etc.) Geofence** (Provable, no PII leak). |
| **Drift Detection** | "Monitor for output inconsistencies." | **Hardware-Parity Binding** (Physical provenance). |
| **Incident Response** | "Revoke access for compromised entities." | **Autonomous Kill-Switch** (Hardware-triggered). |

---

[Auditor Guide](./docs/auditor.md) | [IETF WIMSE Draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/)
