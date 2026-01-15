# Sovereign Ingress: Hardware-Rooted Provenance & ZKP

This document provides the technical specifications for **Stage 1: Verified Ingress** of the AegisSovereignAI framework. While the current PoC focuses on Stage 2 (Egress), this Ingress architecture defines how trust is established "at the glass."

## Technical Implementation Details

### The Attester (User Device)
A managed laptop, mobile device, or edge sensor uses its **Secure Enclave** or **TPM 2.0** to generate an **Entity Attestation Token (EAT)** as specified in `draft-ietf-rats-eat`. This token serves as a "Hardware Passport" for the user.

### The Claim Set
The token includes standard and custom claims:
- `hwmodel`: Hardware model verification.
- `swname`: OS and boot integrity measurements.
- `location-zkp`: A Zero-Knowledge Proof verifying the device is within an authorized geofence without revealing raw GPS coordinates.

### Example Ingress Claim (EAT Format)
The following is a representation of the claims generated at Ingress:

```json
{
  "eat_nonce": "f3b2a...789",
  "ueid": "guid:enterprise-arch-001",
  "oemid": "apple-silicon-m3",
  "location_zkp": {
    "proof": "0x7a2...f8e",
    "circuit": "geo-fence-v1",
    "region": "US-AUTHORIZED"
  },
  "submods": {
    "secure-enclave": { "measurements": "sha256:..." }
  }
}
```

## Unified Ingress: The "JPM App as a Workload" Framework

AegisSovereignAI treats the JPM Application (Mobile or Desktop) as a **First-Class Edge Workload**. By treating the app instance as a workload rather than just a client, we move from "App Security" to **Workload Provenance**.

### 1. Conceptual Mapping to Unified Identity

To align Ingress with the [Unified Identity Model](README-arch-sovereign-unified-identity.md), we "collapse" the architectural distance between the data center and the end-user device:

| Unified Identity Component | Data Center / Edge Server | **Ingress: JPM App (The Workload)** |
| :--- | :--- | :--- |
| **Workload Identity** | SPIRE SVID (Server App) | **SPIRE SVID (JPM App Instance)** |
| **Host Integrity Manager** | Keylime (TPM 2.0) | **Apple App Attest / Windows SGRM** |
| **Location Provider** | GNSS / Mobile Sidecar | **Location ZKP (Device-side)** |
| **Unified Credential** | SVID with Geo Claims | **SVID with Ingress Context Claims** |

---

### 2. The Unified Ingress Flow

The Ingress process is a **Remote Attestation Loop** that mirrors the backend pipeline:

#### **A. Boot-time & Runtime Attestation ("The Keylime Role")**
The JPM App instance invokes the native platform hardware—**Secure Enclave** (Apple) or **TPM/SGRM** (Windows)—to generate a hardware-rooted "Quote." This replaces the need for a separate Keylime Agent on the end-user OS.

#### **B. Workload Identity Issuance ("The SPIRE Role")**
Once the hardware and app integrity are verified by the **Aegis Verifier**, the **Aegis Control Plane** issues a short-lived **Unified SVID**. This certificate contains the `grc.geolocation` and `grc.tpm-attestation` claims required for Sovereign Loop access.

#### **C. Access Enforcement ("The Envoy Role")**
The JPM App presents its **Unified SVID** to the Ingress Gateway (**Envoy**). Envoy’s WASM filter validates the **Attested Claims** inside the SVID, ensuring the workload is untampered and geofence-compliant before allowing access to sensitive PII or AI models.

---

## The Runtime Perception Gap: "Gaslighting" the OS

Hardware attestation (TPM/SGRM) proves the "Identity" and "Health" of the OS kernel. However, **Location** is an input that the OS receives from its environment. A malicious user with administrative access on an unmanaged device can "gaslight" the system after it has successfully booted.

### Common Runtime Compromise Vectors
1.  **API Hooking (Frida/Xposed)**: An attacker intercepts the `Geolocation.getPosition()` call at the app level and returns a pre-programmed "Green Zone" coordinate, bypassing OS-level checks.
2.  **Virtual Driver Injection**: An attacker installs a signed but malicious virtual GNSS driver. The TPM sees a "clean" driver list, but the driver is feeding synthetic data into the system.
3.  **Mock Location Services**: Malware or developer tools toggle system-level mock location providers to spoof coordinates without triggering standard "root detection" flags.

### Aegis Mitigation: Multi-Factor Provenance
AegisSovereignAI closes the Perception Gap by moving beyond single-source trust:
- **Mobile Sensor Sidecar**: Instead of trusting the OS's high-level API, raw sensor data (Cell Tower ID, WiFi triangulation, GNSS signal delay) is verified via a hardware-rooted sidecar.
- **ZKP Integration**: The location claim is bound to a hardware-rooted **Entity Attestation Token (EAT)**. A spoofed location from an unmanaged OS will not have the corresponding signed sensor footprint from the Secure Enclave, causing the ZKP verification to fail at the Ingress Gateway.

## The Unmanaged Device (BYOD) Challenge

For a Tier-1 institution, securing **Bring Your Own Device (BYOD)** interactions—for both retail customers and employees—presents a unique challenge: the "Identity vs. License" gap. While modern operating systems have native security agents, for unmanaged devices, these agents are often **"Active but Silent."**

- **Managed Devices**: Health reports are sent to an enterprise verifier (e.g., Intune) and enforced via MDM.
- **Unmanaged Devices**: Measurements stay "trapped" in the local TPM. If a kernel exploit is active, the system may detect it, but there is no verifier to "hear" the alarm.

### AegisSovereignAI: Bridging the Gap
AegisSovereignAI provides the **Verifier Service** for these unmanaged endpoints. Instead of requiring a full MDM enrollment, the framework utilizes **Point-in-Time Attestation** during the AI session.

1.  **Trigger**: When the user opens the JPMC AI Suite, the app requests a **Hardware-Rooted Health Report**.
2.  **Signing**: The device's **TPM (Windows)** or **Secure Enclave (Apple)** signs the report, binding it to the current session nonce.
3.  **Verification**: The app sends this report to the **Aegis/Keylime Verifier** in the Sovereign Cloud.
4.  **Enforcement**: The bank achieves **"MDM-level Certainty"** for that specific transaction, even on personal hardware.

## Cross-Platform Attestation Signals
To support a diverse enterprise fleet, the Aegis Ingress stage interprets different hardware-rooted signals:

| Feature | Windows SGRM | Linux IMA | Apple App Attest | Android Key Attest |
| :--- | :--- | :--- | :--- | :--- |
| **Philosophy** | **Assertion-Based** | **Audit-Based** | **App-Bound Integrity** | **Key-Bound Integrity** |
| **Mechanism** | Violations (VTL-1). | Unified audit log. | Hardware-bound keys. | Hardware-bound certs. |
| **Agent** | "Octagon" (SGRM). | Kernel IMA. | Secure Enclave. | StrongBox / TEE. |
| **Call / API** | `GetRuntimeAttestationReport` | `ima_measurement_list` | `DCAppAttestService` | `KeyGenParameterSpec` |

### Mobile & Desktop Ecosystem (iOS, Android, macOS, Windows)
Aegis provides a unified security strategy for billions of managed and unmanaged endpoints:
1.  **Apple (iOS & Apple Silicon macOS)**: Uses **App Attest** for app-level hardware binding. Note that on macOS, App Attest requires **Apple Silicon** (M-series chips). For JPMC-managed hardware, **Managed Device Attestation (MDA)** provides enterprise policy enforcement across both iOS and macOS (Intel & Silicon).
2.  **Android (StrongBox/TEE)**: Uses **Android Key Attestation**. The Aegis Verifier validates the hardware-rooted certificate chain (signed by Google's Root CA) to prove the device is not rooted (Bootloader status) and that the banking app's keys are stored in a dedicated **StrongBox** or **Trusted Execution Environment (TEE)**.

> [!TIP]
> **Strategic Alignment (Apple PCC)**: AegisSovereignAI aligns with the architecture of **Apple’s Private Cloud Compute (PCC)**. Both models utilize a "Trusted Loop" where the Secure Enclave is used at both ends—on the user device and in the sovereign data center—to create end-to-end cryptographic proof of software and hardware integrity.

## Privacy-Preserving Geofencing & Identity

### A. Location ZKP (Compliance Proof)
The Ingress stage utilizes ZKP circuits (e.g., Halo2 or Noir) to ensure the institution can verify compliance (e.g., **Regulation K**) without the liability of tracking or storing the user's exact movement history.

### B. Identity ZKP (Zero-Knowledge KYC)
The device uses its **Secure Enclave** to prove the user is an authorized employee or customer (e.g., "Level 4 clearance") without re-transmitting sensitive PII (SSNs, Account IDs) for every AI prompt.
*   **Value:** This prevents **Prompt Injection-based Data Harvesting**. Without ZKP-verified Ingress, attackers could spoof IDs to trick the RAG system into leaking sensitive balances or proprietary data.

## Roadmap Integration
This Ingress framework is designed to integrate seamlessly with the upstream-ready SPIFFE/SPIRE and Keylime identity pipeline implemented in this POC. By leveraging native platform agents (SGRM/IMA), AegisSovereignAI provides a scalable path to securing billions of "unmanaged" end-user endpoints.
