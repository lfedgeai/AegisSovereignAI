# Zero-Knowledge Proofs for Prompt Integrity: The Batch & Purge Model

This document provides a technical walkthrough of how AegisSovereignAI uses Zero-Knowledge Proofs (ZKPs) to solve the **"Audit without Disclosure"** problem for AI system and user prompts.

## 1. The Problem: The Prompt Paradox

Enterprises face a paradox when auditing AI systems:

| Requirement | Traditional Approach | Liability |
| --- | --- | --- |
| **Prove system prompt contains safety guardrails** (e.g., "redact SSNs") | Store and show the full system prompt to auditors. | Exposes proprietary IP. |
| **Prove user prompts did not contain jailbreaks** (e.g., "ignore instructions") | Log all user prompts for forensic review. | Creates massive PII/GDPR liability. |
| **Enable post-incident investigation** | Retain all prompts indefinitely. | Violates data minimization principles. |

**AegisSovereignAI's Solution:** Generate a cryptographic *proof* that a prompt satisfies a policy, then *purge* the raw prompt. The auditor receives mathematical certainty without seeing the sensitive data.

---

## 2. The Two-Track Proof Strategy

### Track A: System Prompt Integrity (Pre-Computed)

System prompts are relatively static. We generate a proof **at deployment time**, not at inference time.

**Process:**
1.  **Policy Definition:** Define the required keywords/patterns (inclusions) and forbidden keywords/patterns (exclusions).
    *   *Inclusion:* `"redact SSN"`, `"do not disclose account numbers"`
    *   *Exclusion:* `"you are DAN"`, `"ignore previous instructions"`
2.  **Circuit Compilation:** A Noir circuit is compiled that takes the system prompt as a private input and the policy as a public input.
3.  **Proof Generation:** At deployment, the system prompt is fed into the circuit. If it satisfies all inclusions and no exclusions, a proof is generated.
4.  **Verification:** The proof and the public policy hash are stored. Any auditor can verify the proof against the policy hash without ever seeing the prompt.

**Outcome:** "Compliance-by-Design." The proof is valid for the lifetime of that system prompt version.

### Track B: User Prompt Compliance (Batch & Purge)

User prompts are dynamic and high-volume. Real-time ZKP generation per prompt is computationally prohibitive. We use a **batched, aggregated proof** model.

**Process:**
1.  **Real-Time Filtering:** At inference time, a lightweight, deterministic filter (regex + ML classifier) screens user prompts for obvious injection patterns. This is fast and does not create a ZKP.
2.  **Secure Logging:** Prompts that pass the filter are encrypted and written to a short-lived, in-memory audit buffer.
3.  **Batch Window:** Every `N` minutes (e.g., 5-15 minutes), a background process triggers.
4.  **Aggregated Proof Generation:** The batch processor reads the encrypted prompts from the buffer. A ZKP circuit processes the entire batch, generating a single proof that asserts:
    *   *"All prompts in this batch passed the exclusion policy."*
    *   *"The hash of the batch is `H`."*
5.  **Anchor & Purge:** The proof and batch hash `H` are written to an immutable audit log (e.g., a blockchain or append-only ledger). The raw prompts in the buffer are then **permanently purged**.

**Outcome:** The auditor receives a chain of batch proofs. They can verify that *every* batch in a given time window was compliant, without ever accessing the raw prompts.

---

## 3. The Noir Circuit (Conceptual)

The core logic of the ZKP circuit is straightforward:

```noir
// Conceptual Noir Circuit for Prompt Policy Verification
fn main(
    prompt: [u8; MAX_PROMPT_LEN],         // Private: The raw prompt (never disclosed)
    policy_inclusions: [[u8; 64]; N],     // Public: Keywords that MUST be present
    policy_exclusions: [[u8; 64]; M],     // Public: Keywords that MUST NOT be present
    policy_hash: Field                    // Public: Hash of the policy for integrity
) -> pub bool {

    // 1. Verify policy integrity
    assert(hash(policy_inclusions, policy_exclusions) == policy_hash);

    // 2. Check all required inclusions are present
    for i in 0..N {
        assert(contains(prompt, policy_inclusions[i]));
    }

    // 3. Check all forbidden exclusions are absent
    for j in 0..M {
        assert(!contains(prompt, policy_exclusions[j]));
    }

    true // Proof generated only if all assertions pass
}
```

---

## 4. The Evidence Bundle for Auditors

When an auditor requests compliance evidence, they receive an **Evidence Bundle**:

```json
{
  "audit_window": {
    "start": "2026-01-20T14:00:00Z",
    "end": "2026-01-20T14:15:00Z"
  },
  "system_prompt": {
    "version": "v3.2.1",
    "proof": "base64-noir-proof...",
    "policy_hash": "sha256:a1b2c3..."
  },
  "user_prompt_batches": [
    {
      "batch_id": "batch-001",
      "timestamp": "2026-01-20T14:05:00Z",
      "prompt_count": 1247,
      "batch_hash": "sha256:d4e5f6...",
      "proof": "base64-noir-proof...",
      "status": "COMPLIANT"
    }
  ],
  "signatures": {
    "aegis_control_plane_jws": "eyJhbGciOiJSUzI1NiIs..."
  }
}
```

---

## 5. Regulatory Mapping

| Regulatory Requirement | ZKP Proof Element |
| --- | --- |
| **EU AI Act Art. 10 (Data Governance)** | System Prompt Integrity Proof |
| **NIST AI RMF (GOVERN)** | Policy-as-Circuit for transparent enforcement |
| **GDPR Art. 5 (Data Minimization)** | Batch & Purge model eliminates long-term PII storage |
| **OCC 2021-12 (Third-Party Risk)** | User Prompt Compliance Proof for vendor AI models |

---

[Root README](../README.md) | [Auditor Guide](./auditor.md) | [IETF WIMSE Draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/)
