# Appendix — Comparison Tables

## Table 1: TEE-Approximated Location vs ZKP Geolocation Proof

| Dimension | TEE (code in enclave) | ZKP (Plonky2 circuit) |
|---|---|---|
| **Privacy model** | Approximation — coarsens coords (±5km). Algorithms can narrow. | Mathematical — exact coords are private witness. Zero leakage. |
| **Verifiability** | Must trust TEE vendor (Intel/AMD/Arm). Attestation = "this code ran." | Self-contained proof. Anyone can verify. No vendor trust required. |
| **Hardware dep.** | Requires TDX/SEV/TZ hardware. Vendor lock-in. | Runs on any CPU. Plonky2 maps to native 64-bit. |
| **Attack surface** | Large TCB: microcode, firmware, side-channels (Spectre, Foreshadow, ÆPIC). | ~120 lines of arithmetic. No side-channels, no microcode bugs. |
| **Post-quantum** | Attestation relies on ECDSA/RSA → quantum-vulnerable. | Poseidon hash (no EC curves) → PQC-resistant. |
| **Composability** | Hard to compose multi-enclave attestations. | Recursive proof composition — fold N proofs into 1. |
| **Data sovereignty** | Approximated coordinates still leave the device. | No location data leaves device. Only boolean proof crosses network. |

---

## Table 2: TEE Integrity vs Confidentiality Tradeoff

| What TEE delivers | Assessment | Detail |
|---|---|---|
| **Runtime confidentiality** | ✅ Strong | Encrypted memory, OS can't read it |
| **Load-time integrity** | ✅ Effective for static workloads | Measures binary at load; runtime monitoring requires additional tooling |
| **ASLR** | ⚠️ Tradeoff | Often disabled for consistent launch measurement → predictable code layout |
| **Side-channel resistance** | ⚠️ Active research | Shared CPU microarchitecture → known vectors (Spectre/Foreshadow), mitigations evolving |
| **AI agent compatibility** | ⚠️ Considerations | Dynamic runtimes (Python, JIT) increase TCB; ASLR tradeoff more significant |
| **Net assessment** | ⚠️ Complementary | Strong confidentiality; integrity tradeoffs benefit from additional layers |

### Considerations for AI Agent Workloads

CC was designed for static, well-defined workloads (databases, key stores). AI agents introduce additional complexity:

| AI Agent Property | Why CC ASLR-disable hurts |
|---|---|
| **Python/PyTorch runtime** | Interpreted, dynamically linked — can't statically compile |
| **JIT kernels (CUDA, XLA)** | Generate executable code at runtime — W^X conflicts |
| **Model weight loading** | Weights loaded at inference, not baked into launch image |
| **Plugin/tool systems** | Agents dynamically import tools, spawn subprocesses |
| **Net effect** | Larger attack surface with predictable layout warrants additional integrity layers |

> When ASLR is disabled for launch measurement, dynamic workloads may benefit from complementary integrity mechanisms such as IMA/Keylime and ZKP-based verification.

---

## Table 3: Threat Matrix — ZKP × TEE × ZKP-inside-TEE

| Threat | ZKP alone | TEE alone | ZKP inside TEE |
|---|---|---|---|
| Verifier learns GPS | ✅ hidden | ❌ output | ✅ hidden |
| Kernel 0-day reads GPS | ❌ ptrace | ✅ encrypted | ✅ both protect |
| TEE side-channel leaks data | n/a | ❌ Spectre | ✅ proof only |
| Fake GPS from compromised OS | ❌ | ⚠ ecalls* | ⚠ ecalls* |

\* Mitigated by SR-IOV (DMA-isolated sensor) + signed location from GPS hardware.
Requires: IOMMU + SR-IOV-capable sensor + driver in enclave TCB.

---

## Table 4: Where to Run the ZKP Prover

| Option | Confidentiality | ASLR | Side-channels | Sensor access | Status |
|---|---|---|---|---|---|
| **Userspace sidecar** | ❌ ptrace-able | ✅ Full | ✅ None | ❌ via OS | Today's POC |
| **TDX/SEV confidential VM** | ✅ Encrypted | ❌ Disabled | ❌ Shared CPU | ⚠ ecalls | Deployment option |
| **Management processor (HPE iLO 7 / Dell iDRAC)** | ✅ Separate RAM | ✅ Full | ✅ Separate CPU | ✅ Direct | ← Strongest |

---

## Table 5: ASLR and Attestation — The Tradeoff

| Measurement approach | ASLR compatible? | Quote consistency | Notes |
|---|---|---|---|
| **VM launch image** (MRTD / LAUNCH_DIGEST) | ⚠ Often disabled | ✅ Consistent | TDX/SEV pre-launch |
| **IMA file hash** (Keylime) | ✅ Fully compatible | ✅ Consistent | Measures files, not memory layout |
| **Memory layout** (MRENCLAVE / SGX) | ❌ Must be disabled | ✅ Consistent | Deprecated in favor of TDX |
| **Firmware image** (HPE iLO 7 Silicon Root of Trust) | ✅ Fully compatible | ✅ Consistent | Separate processor |

---

## Table 6: Defence in Depth — WHO / WHERE / WHAT / HOW

| Layer | Technology | What it proves | What defeats it | Correlation |
|---|---|---|---|---|
| **WHO** | SPIFFE ID (SPIRE CA) | Identity of the workload | CA compromise | Cert bound to TPM AK |
| **WHERE** | ZKP proof (TPM-sealed) | Location within geofence | GPS RF spoofing + kernel 0-day | idhash binds to TPM |
| **WHAT** | IMA digest (Keylime) | Binary integrity | In-memory rootkit | TPM quote seals hash |
| **HOW** | TPM AK attestation | Hardware binding | Physical TPM extraction | HPE iLO 7 chassis detects |

> An attacker must simultaneously defeat ALL layers. Compromising one does NOT help with the others.

---

## Table 7: Management Processor (HPE iLO 7 / Dell iDRAC) vs Co-located TEE

| Property | TDX/SEV | HPE iLO 7 |
|---|---|---|
| **CPU** | Shared with host | Separate ARM CPU |
| **Memory** | Encrypted host RAM | Separate physical RAM |
| **Side-channels** | ❌ Shared microarchitecture | ✅ None — physically isolated |
| **ASLR** | ❌ Disabled for launch quotes | ✅ Preserved — firmware measurement |
| **Sensor access** | Via host OS ecalls | ✅ Direct — no OS mediation |
| **Root of Trust** | Intel/AMD microcode | HPE-signed firmware |
| **Standby power** | Off without AC | ✅ ON if AC connected (host can be off) |
| **Theft detection** | None | ✅ Detects AC disconnect → revoke identity |
| **Attestation** | Memory-level launch measurement | Firmware-level measurement |

---

## Table 8: TCG EK-Based Key Attestation Alignment

| TCG Spec Concept | POC Implementation |
|---|---|
| EK (Endorsement Key) | TPM manufacturer key — root of hardware identity |
| AK (Attestation Key) | TPM AK used in SVID; idhash = SHA-256(AK pub) |
| EK attests AK | SPIRE TPM plugin validates AK provenance |
| firmwareVersion in TPMS_ATTEST | Already in every TPM quote — Keylime can enforce policy |
| Verifier checks firmware before credential | Natural extension: SPIRE CA checks firmwareVersion |

---

## Table 9: Nonce Chaining — Auditability [ROADMAP]

```
nonce[0] = HMAC(secret, 0 || seed)
nonce[1] = HMAC(secret, 1 || nonce[0])
nonce[n] = HMAC(secret, n || nonce[n-1])
```

| Property | Random nonce | Counter only | HMAC chain |
|---|---|---|---|
| **Non-repeating** | ⚠ Probabilistic | ✅ Yes | ✅ Deterministic |
| **Cross-server unique** | ⚠ Probabilistic | ❌ Collide | ✅ Per-server secret |
| **Verifiable sequence** | ❌ No ordering | ✅ Ordered | ✅ Ordered + unpredictable |
| **Forward integrity** | ❌ | ❌ | ✅ Can't compute chain[n-1] from chain[n] |
| **Full audit replay** | ❌ | ❌ | ✅ Reconstruct from secret + ledger |
| **Reproducible build** | ❌ | ❌ | ✅ Rebuild entire chain after reboot |

---

## Table 10: Architecture vs "Just Use TEE"

| Question | TEE-only answer | This architecture |
|---|---|---|
| **Confidentiality?** | ✅ Encrypted memory | ✅ ZKP (no data crosses network) |
| **Integrity?** | ⚠ Load-time only, ASLR disabled | ✅ Runtime IMA + full ASLR |
| **Verifiability?** | "Trust the enclave" | ✅ Mathematical proof, anyone can verify |
| **Location privacy?** | ❌ Not addressed | ✅ ZKP geofence, coords never revealed |
| **Audit trail?** | ❌ Not addressed | ✅ HMAC nonce chain + ledger [ROADMAP] |
| **Theft detection?** | ❌ Power off = gone | ✅ Management processor standby power, AC disconnect → revoke |
| **Post-quantum?** | ⚠ ECDSA/RSA attestation | ✅ Poseidon hash, PQC roadmap |
