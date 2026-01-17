# AegisSovereignAI: Verifiable Trust from Silicon to Prompt

**Securing the Agentic Enterprise through Physical Determinism and Radical Privacy.**

## Executive Summary: From "Best-Effort" to Verifiable Intelligence

In the Agentic AI era, traditional "wrapper-based" security—firewalls, static tokens, and text filters—is no longer sufficient. These methods are bypassable, add latency, and fail to provide the mathematical proof required by global regulators.

**AegisSovereignAI** transforms AI security from "Best-Effort" to **Verifiable Intelligence**. We provide a contiguous **Sovereign Trust Loop** that ensures:

* **Physical Determinism:** Binds AI responses to benchmarked hardware to mitigate **Hardware-Induced Drift**.
* **Compliance without Liability:** Utilizes **Zero-Knowledge Proofs (ZKP)** to provide mathematical evidence of residency (**Regulation K**) and integrity without ingesting or storing sensitive PII.
* **Autonomous Resilience:** A hardware-rooted **Autonomous Revocation Loop** that "ghosts" compromised agents from the fabric in real-time.

![AegisSovereignAI Architecture Summary](images/readme-arch-new-summary.svg)

---

---

## Enterprise Sovereign Scenarios: High-Stakes Challenges & Value

Current security architectures for AI face critical gaps. AegisSovereignAI addresses these by securing the entire AI lifecycle through persona-driven verification.

### 1. The Enterprise Customer (Retail/Private Banking End-Consumer)

*   **Core Use Case:** **Private Wealth Gen-AI Advisory (Unmanaged Devices).** Providing high-net-worth clients with AI-driven portfolio insights on their personal, unmanaged devices while guaranteeing that their physical location and identity are never leaked to the public cloud.
*   **Target Need:** Private interactions with Gen-AI advisors without sacrificing civil liberties or location history.
*   **Sovereign Value:** **Radical Privacy.** Users are verified as compliant (e.g., "In the US" or "In a Branch") via ZKP, ensuring the bank meets regulatory metrics (Reg-K) without the privacy liability of storing raw customer movement data.
*   **Impacted Persona:** **CISO & Head of Fraud**

### 2. The Enterprise Employee (Branch Relationship Manager)

*   **Core Use Case:** **Secure Remote Branch Operations.** Allowing Relationship Managers to access sensitive PII from "Green Zone" servers on managed hardware, whether at a branch or a verified remote location.
*   **Target Need:** Frictionless access to sensitive client PII on-site for analysis or loan processing using managed laptops or branch servers.
*   **Sovereign Value:** **Frictionless Compliance.** Instead of manual VPNs or vulnerable passwords, the Hardware Integrity of their device (TPM/Keylime) automatically proves it is untampered and policy-compliant. If the device firmware is compromised, access is revoked cryptographically at the hardware layer.
*   **Impacted Persona:** **VP of Engineering & Cloud Architect**

### 3. The Enterprise Tenant (Line-of-Business Owner)

*   **Core Use Case:** **Regulatory Sandboxing for LOBs.** Enabling the Mortgage and Credit Card divisions to share the same physical Sovereign Cloud while ensuring total cryptographic isolation of their respective AI models and data.
*   **Target Need:** Guarantee that sensitive workloads are isolated even when sharing Sovereign Cloud infrastructure.
*   **Sovereign Value:** **Multi-Tenant Isolation.** Trust is established via Cryptographic Identity (SPIFFE/SVID) rather than network location. This provides hardware-enforced isolation between business units, even on shared silicon.
*   **Impacted Persona:** **Head of AI & Model Risk Management (MRM)**

### 4. The Enterprise Stakeholder (Chief Risk/Sovereignty Officer)

*   **Core Use Case:** **Automated Regulatory Audit.** Providing a real-time, mathematical proof-of-compliance for regulators (OCC/ECB), demonstrating that every AI interaction—across all retail devices, employee hardware, and Managed Data Center Infrastructure—was verified by hardware and compliant with data residency laws.
*   **Target Need:** Deterministic, math-based proof that data residency and sovereignty policies are strictly enforced.
*   **Sovereign Value:** **Compliance without Liability.** By using ZKP-based location proofs, the Risk Officer can prove regional residency to regulators without the bank ever having to ingest or store high-resolution, high-liability customer location data.
*   **Impacted Persona:** **Chief Risk Officer & AI Auditor**

---

## Technical Root Causes: Six Dimensions of Failure

To address the enterprise scenarios above, we must solve for the specific technical failures that traditional IT security cannot mitigate.

### 1. The Fragility of Identity & Geofencing
Traditional security relies on **bearer tokens** and **IP-based geofencing**, which are fundamentally non-binding and easily spoofed.
* **Replay Attacks:** Standard tokens function like a physical key; if a malicious actor intercepts a token, they can replay it to impersonate a legitimate workload (e.g., an AI agent).
* **VPN-based Spoofing:** IP-based location checks are trivial to bypass using VPNs, allowing remote attackers to appear within "Green Zones."

### 2. The Residency vs. Privacy Deadlock
Regulators require proof of data residency (Reg-K), but traditional geofencing relies on ingesting high-resolution GPS data, creating massive PII liability under GDPR. Banks are often forced to choose between non-compliance or privacy violation.

### 3. Infrastructure Blind Spots & Administrative "Gaslighting"
Modern AI workloads are vulnerable to **"Gaslighting"**—where a compromised OS or Hypervisor feeds fake sensor/location data to the application (e.g., via Frida hooks), tricking compliance logic while the device is in an unauthorized jurisdiction.

### 4. The "Silicon Lottery": Hardware-Induced Drift
AI drift is physically anchored to hardware. Even at `temperature=0`, a model running on an NVIDIA A100 can produce different numerical results than on an H100 due to non-associative math and thread-timing variations. Without **Physical Provenance**, there is no way to verify if a decision diverted due to unauthorized hardware migration.

### 5. The Black-Box Governance Gap
AI models are non-deterministic, making them difficult to audit. Governance today is mostly "AI-Washing"—static policy documents that do not actually control the model. There is no mathematical proof that a specific decision was made by an untampered model.

### 6. The Multi-Agent Chain Reaction & Capability Bleed
If one agent is compromised (e.g., via indirect prompt injection), it can "bleed" its capabilities into the next in an autonomous chain reaction. Traditional security monitors Human-to-Machine traffic but is blind to internal Agent-to-Agent logic drifts.

---

## Identifying the 2026 Standard & Open Source Gaps

To make the **AegisSovereignAI** solution more obvious, it is critical to highlight the specific architectural "blind spots" in existing industry standards and open-source tools. In 2026, while the **CSA**, **NIST**, and **OWASP** provide the policy foundation, they often fall short at the execution layer—particularly regarding the non-deterministic nature of AI and the machine-speed requirements of autonomous agents.

### 1. CSA AI Controls Matrix (AICM) Gaps

* **The Remediation Gap:** While the AICM (v1.1) provides 243 controls for visibility, it is primarily an audit framework. It lacks a native **Remediation Layer**. In 2026, the differentiator is no longer just "seeing" the risk, but the ability to translate insight into automated action (e.g., revoking a non-human identity in milliseconds).
* **Static Identity Limitation:** CSA identity controls still lean heavily on OAuth and API-key-based models. These do not account for **Blended Identities**, where an agent and a human share permissions. Aegis fills this by moving from "Bearer Tokens" to **Hardware-Attested Identities**.

### 2. NIST AI RMF (Measure & Govern) Gaps

* **The "Measurement" Bottleneck:** The NIST AI RMF (1.0/2.0) defines the *Measure* function but lacks standardized, executable code for measuring **Hardware-Induced Drift**. Most NIST-aligned tools monitor software drift but are blind to the "Silicon Lottery" effect where identical prompts diverge due to GPU-level non-associative math.
* **The Legal-Engineering Handoff:** NIST focuses on "Explainability," yet there is a massive gap in **Policy-to-Practice Traceability**. Legal teams write policies, but engineering teams lack a mechanism to prove that those policies were enforced at the exact moment of inference.

### 3. Open Source Fragmentation Gaps

* **The Point-Solution Trap:** Most open-source AI security projects (e.g., specific LLM guardrails or scanners) are **"Point-Specific."** They secure the prompt (Layer 3) or the container (Layer 1), but they do not bridge them. This fragmentation allows for **Context Contamination**, where toxic data is injected into an agent's memory via an unverified infrastructure channel.
* **The Production Gap:** Existing tools lack a unified **"Silicon-to-Audit" Ledger**. When an incident occurs, an analyst must manually correlate logs from the GPU, the SPIRE server, and the AI framework. Aegis provides the **Immutable Triad** as a single, verifiable proof.

---

## How Aegis Operationalizes the Gaps

AegisSovereignAI serves as the **Execution Engine** for these frameworks, transforming static policies into hardware-enforced circuits.

* **For CSA:** We provide the **Remediation Loop** via the **Autonomous Revocation** of SPIRE SVIDs, moving from audit to active defense.
* **For NIST:** We operationalize the **MEASURE** function by binding the **Hardware Quote** to the decision, ensuring that drift can be traced back to its physical origin.
* **For Open Source:** We provide **AI-Specific Orchestration** that bridges the "Plumbing" (CCC enclaves) with the "Policy" (OPA/Permit.io).

### Comparison Summary: Framework vs. Execution

| Need | CSA/NIST Guidance | Aegis Execution |
| --- | --- | --- |
| **Residency Proof** | "Use geofencing for data residency." | **ZKP-Geofence** (Provable, no PII leak). |
| **Drift Detection** | "Monitor for output inconsistencies." | **Hardware-Parity Binding** (Physical provenance). |
| **Incident Response** | "Revoke access for compromised entities." | **Autonomous Kill-Switch** (Hardware-triggered). |

---

## The Three-Layer Trust Architecture

AegisSovereignAI acts as the unifying control plane that cryptographically binds silicon-level attestation to application-level governance.

### Layer 1: Infrastructure Security (The Confidentiality Upgrade Path)

* **Confidential Computing (CC) & TEEs:** Integrates with **Intel TDX** and **NVIDIA H100 TEEs** to ensure model weights and context remain encrypted in-use, shielding them from privileged admins.
* **Integrity for Legacy/Edge:** On commodity hardware, Aegis uses **Keylime** and **TPM 2.0** to verify the software stack's **Integrity** (via IMA/EVM). See the [Hybrid Cloud PoC](./hybrid-cloud-poc/README.md) for details.

### Layer 2: Workload Identity (The Provable Bridge)

* **Unified Identity (SPIRE):** Binds SPIRE workload identities to hardware credentials (TPM). An agent cannot execute unless it is on a verified, authorized machine.
* **Autonomous Revocation:** If a node's hardware state drifts (detected by Keylime), its SPIRE identity is revoked in real-time, isolating the agent before lateral movement.

### Layer 3: AI Governance (Verifiable Logic & Privacy)

* **Policy-as-Circuit:** Rules are compiled into **zk-SNARK circuits**, providing an immutable **Certificate of Compliance** for every AI decision.
* **Audit without Disclosure:** Prove the AI used a specific audited model version and benchmarked hardware profile without revealing proprietary weights or sensitive PII.

![AegisSovereignAI Architecture](images/readme-arch-new.svg)

---

## The Sovereign Supply Chain: End-to-End Trust

AegisSovereignAI applies its three-layer architecture across the entire AI lifecycle.

| AI Lifecycle Stage | Layer 1: Infrastructure | Layer 2: Identity | Layer 3: Governance |
| --- | --- | --- | --- |
| **Data Ingestion** | Secure enclaves protect raw PII during ingestion. | **FDO** ensures sensor hardware is genuine. | **ZKP-RAG** ensures data provenance without disclosure. |
| **Model Training** | **Intel TDX** prevents admin snooping of weights. | Sigstore-signed datasets ensure data integrity. | **Fairness Auditing** via privacy-preserving circuits. |
| **Model Inference** | **NVIDIA H100 TEEs** encrypt prompts and weights. | **Unified SVID** binds inference to verified silicon. | **ZKP Compliance Receipts** prove execution matched policy. |

---

## Addressing Complexity: The ZKP Performance Reality

A common concern with ZKP is the computational "tax." Aegis addresses this through a **Hybrid Performance Model**:

1. **Succinctness:** We utilize **zk-SNARKs**, where the resulting proof is tiny (**<1 KB**) and verified in **milliseconds**.
2. **Asynchronous Proving:** Proof generation happens in parallel to AI inference. The AI responds instantly, while the "Compliance Receipt" is attached moments later.
3. **Tiered Verification:** Use ZKP for high-value governance (legal/financial) while using lightweight **Hardware Attestation** (TPM) for routine operations.

---

## Strategic Differentiation

| Feature | Legacy AI Security | Aegis Sovereign AI |
| --- | --- | --- |
| **Trust Model** | Implicit (Trust the Provider) | **Explicit (Verify the Math)** |
| **Data Privacy** | Redaction / Masking | **Mathematical Privacy (Zero-Disclosure)** |
| **Auditability** | Forensic Logs (Post-Facto) | **Deterministic Proofs (Real-Time)** |
| **Hardware** | Unprotected / Cloud-only | **Hybrid (Confidential + Standard TPM)** |

---

## Competitive Landscape

Aegis provides **AI-specific orchestration** on top of foundational security primitives:

| Project | What They Provide | Aegis Differentiator |
| --- | --- | --- |
| **Confidential Computing (CCC)** | The *plumbing* (enclaves) | **AI-Specific Orchestration**—binding enclaves to AI identities and OPA governance. |
| **Agentic Frameworks (AAIF / MCP)** | Capabilities (how agents communicate) | **Identity-First**—verifying *who* is talking and if they are on verified silicon. |
| **Skyflow / Protecto** | SaaS Data Privacy Vaults | **Infrastructure-Intrinsic**—ensuring the vault logic itself runs on verified silicon. |
| **Guardrails AI / NeMo** | Filter-Based Protection | **Structural Security**—hardware-isolated agents via Intent-Generation Separation. |
| **Policy Engines (OPA / Permit)** | "Can this happen?" | **"Proof it DID happen"**—ZK-Receipts prove execution matched policy exactly. |

---

## Driving AI Security Standards

Aegis turns high-level frameworks into **executable, verifiable code**.

### OWASP Top 10 for LLMs

* **LLM01 (Prompt Injection):** **Hardware-Verified Intent Tunnels**—LLMs only accept input signed by a hardware-attested classifier.
* **LLM06 (Sensitive Data Disclosure):** Our **ZKP-RAG** implementation serves as a reference guardrail for privacy-preserving retrieval.

### Cloud Security Alliance (CSA) - AI Security Stack

* **Hardware-Rooted AI Workload Identity:** Leveraging our **IETF WIMSE** work to move the industry from "Bearer Tokens" toward **Attested Identities**.

### NIST AI Risk Management Framework (AI RMF)

Aegis provides the first measurement engine for AI security:

> **The Immutable Triad**
> `Audit Log = Hash(Input) + Hash(Context) + Hash(Model Config)`
> Every AI decision carries cryptographic proof of exactly what input, context, and model version produced the output—enabling **Verifiable AI Audit Logs**.

---

## Implementation & Quick Start

* **Hybrid Cloud PoC:** Full integration of **SPIRE** and **Keylime** for [Real-Time Node Revocation](./hybrid-cloud-poc/README.md).
* **Unified Identity Architecture:** Technical deep-dive into [Managed vs. BYOD Workload Provenance](./hybrid-cloud-poc/README-arch-sovereign-unified-identity.md).
* **Threat Model:** Analysis of the [Runtime Perception Gap and Sensor Fusion](./hybrid-cloud-poc/THREAT-MODEL-runtime-perception-gap.md).

---

[Auditor Guide](./docs/auditor.md) | [IETF WIMSE Draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/) | [ZKP Deep Dive](./docs/zkp.md)