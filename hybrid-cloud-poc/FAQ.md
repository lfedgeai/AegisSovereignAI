# Frequently Asked Questions

## Architecture

### Why not just use Confidential Computing (TDX/SEV)?

Confidential Computing and Zero-Knowledge Proofs solve **different problems** — they are complementary, not competing:

| | CC (TDX/SEV) | ZKP + Keylime/IMA |
|---|---|---|
| **Solves** | Runtime confidentiality (memory encryption) | Provable integrity + provable location |
| **Proves** | Host OS cannot read workload memory | Binary hasn't been tampered with; workload is inside a geofence |
| **Tradeoff** | ASLR often disabled for launch measurement | No confidentiality guarantee |

For AI workloads specifically, CC faces additional considerations: dynamic runtimes (Python, JIT-compiled CUDA, plugin systems) increase the Trusted Computing Base, and side-channels remain a concern due to shared CPU microarchitecture.

This architecture uses file-level measurement (Keylime/IMA) for integrity and ZKP for privacy-preserving location. TDX/SEV is a supported deployment option for the ZKP prover — combining both gives you confidentiality **and** provable integrity + location.

### Why not just use a VPN and IP geolocation?

IP geolocation is an approximation based on BGP routing tables — trivially spoofable with a VPN or cloud VM in the target region. It provides neither verifiability nor privacy.

Our approach is rooted in physics (GPS/GNSS hardware with signed location) and bound to silicon (TPM Attestation Key). The ZKP proves the workload is inside a geofence without revealing the exact coordinates — IP geolocation does neither.

### What is the performance overhead?

The architecture separates the **Identity Control Plane** from the **Inference Data Plane**:

- Heavy auditing (management processor, Keylime) runs out-of-band
- The AI workload only sees a short-lived SVID — one mTLS handshake
- ZKP proof generation happens once per attestation cycle (configurable, typically minutes to hours)
- ZKP verification is fast (milliseconds), and occurs on SVID renewal

No latency is added to the AI inference hot path.

---

## Security

### How does defence in depth work?

The architecture implements a **layered trust model** where compromising one layer does not help with the others:

| Layer | Technology | Proves | Defeated by |
|---|---|---|---|
| **WHO** | SPIFFE ID (SPIRE CA) | Workload identity | CA compromise |
| **WHERE** | ZKP proof (TPM-sealed) | Location within geofence | GPS RF spoofing + kernel 0-day |
| **WHAT** | IMA digest (Keylime) | Binary integrity | In-memory rootkit |
| **HOW** | TPM AK attestation | Hardware binding | Physical TPM extraction |

An attacker must simultaneously defeat ALL layers.

### Can the management processor detect a memory-only RCE?

Management processors (e.g., HPE iLO 7, Dell iDRAC) measure firmware, not runtime memory. That's why IMA/Keylime is layered on top — it continuously measures file hashes via TPM quotes. A persistent exploit is caught at next file access. A memory-only exploit dies at reboot, and the TPM-sealed attestation nonce confirms a clean restart.

For runtime memory confidentiality, TDX/SEV can be added as a complementary layer (Option 2 in the prover deployment model).

### What about GPS spoofing?

GPS RF spoofing requires physical proximity and expensive equipment — and it only defeats one layer. Mitigations include:

1. **GPS with signed location** from sensor hardware
2. **SR-IOV / VFIO** for DMA-isolated sensor access — OS cannot intercept the data path
3. **Network latency nonces** as an independent cross-check
4. **Management processor chassis ID** for physical binding

An attacker would need to simultaneously spoof the GPS, compromise the kernel, AND defeat the TPM binding.

### Why trust the SPIRE server?

The SPIRE server is measured by Keylime like any workload — IMA hashes its binary, the TPM quote seals that measurement. If someone swaps the SPIRE server binary, the next Keylime attestation fails and the system enters Safe State.

The SPIRE server is not a trust anchor; it's a **verifiable participant**. A planned enhancement is recursive HMAC nonce chaining (sealed to the physical TPM) so that even pausing the attestation cycle becomes detectable.

---

## Cryptography

### Is HMAC-SHA256 sufficient for long-term audit trails?

For the pre-quantum era, yes. The HMAC primitive is quantum-resistant — Grover's algorithm gives only √ speedup, so 256-bit remains 128-bit effective, well above the security threshold.

For signatures in the mTLS certificate chain, the project tracks NIST PQC standards (ML-KEM/ML-DSA) for migration readiness.

### Why Plonky2 for zero-knowledge proofs?

| Property | Benefit |
|---|---|
| **No trusted setup** | Transparent — no ceremony, no toxic waste |
| **Hash-based commitments** | Poseidon hash (no elliptic curves) → post-quantum resistant |
| **Fast** | ~50ms proof generation, millisecond verification |
| **CPU-native** | 64-bit prime field (Goldilocks) maps to native instructions |
| **Recursive** | Proof composition — fold N proofs into 1 |

### What is the device binding (idhash)?

```
idhash = SHA-256(TPM Attestation Key public key)
```

This value is baked into the ZKP circuit as a public input. The proof is bound to a specific physical TPM — you cannot transplant a valid proof to a different device. The verifier checks that the idhash in the proof matches the AK public key in the X.509 certificate.

---

## Operations

### How does workload migration work?

There is no key migration — there is **re-attestation**. The workload gets a new SVID from the destination host's SPIRE agent, which must independently attest via the destination's physical TPM and management processor. The old SVID expires naturally (short TTL).

The identity follows the physical residency, not just the VM. No valid physical attestation on the destination means no new identity.

### What if the sensor hardware doesn't support SR-IOV?

Fallback to VFIO passthrough for the entire device. Less granular but same DMA isolation via IOMMU. Without either, fall back to signed sensor output — the GPS hardware signs its readings, and the ZKP circuit verifies the signature.

### Where can the ZKP prover run?

| Option | Confidentiality | ASLR | Side-channels | Status |
|---|---|---|---|---|
| Userspace sidecar | ❌ ptrace-able | ✅ Full | ✅ None | Today's POC |
| TDX/SEV confidential VM | ✅ Encrypted | ⚠️ Tradeoff | ⚠️ Shared CPU | Deployment option |
| Management processor (HPE iLO 7 / Dell iDRAC) | ✅ Separate RAM | ✅ Full | ✅ Separate CPU | Strongest |

---

## Key Formulas

```
idhash   = SHA-256(TPM AK public key)                           — Device binding in ZKP
SVID     = SPIRE cert + LAH bundle (OID 1.3.6.1.4.1.65284.1.1) — Unified Identity
```

### Roadmap

```
nonce[n] = HMAC(secret, n || nonce[n-1])  — Recursive nonce chaining (planned)
```
