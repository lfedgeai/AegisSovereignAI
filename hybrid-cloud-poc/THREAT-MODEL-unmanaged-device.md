# Threat Model: Unmanaged Device Security (AegisSovereignAI)

**Scenario**: A Retail Banking user (e.g., at JPMC or Citi) is accessing a "Geofenced AI Portfolio Advisor" from an **unmanaged, personal** Android/iOS device (BYOD).
**Objective**: The user (or malware on the device) seeks to exploit an **infrastructure blind spot** to believe they are in a "Green Zone" (e.g., within the US/NY) while physically located in a prohibited or high-risk jurisdiction.

---

## 1. Threat Definition & Scope

| Attribute | Detail |
| :--- | :--- |
| **Trust Boundary** | Between the **Unmanaged Device OS** and the **Unified Identity Plane** (SVID). |
| **Primary Threat** | **Runtime Locality Spoofing** via OS-level manipulation (exploiting an Infrastructure Blind Spot). |
| **Enforcement Mechanism** | Conditional issuance of **Unified SVID** with attested claims. |
| **Impact** | Violation of **Regulation K (Reg-K)**; unauthorized access to sensitive financial models; potential PII leakage. |

---

## 2. Attack Vectors (Exploiting Infrastructure Blind Spots)

Despite a "Clean" Boot-time Attestation, the following runtime vectors are active:

### Vector A: API Hooking (Frida/Xposed)
- **Action**: Intercepts the `FusedLocationProviderClient` call in the banking application.
- **Payload**: Replaces the legitimate coordinates with a static, authorized NY location.
- **Result**: The OS and App believe they are in NY.

### Vector B: Virtual Driver Injection
- **Method**: Attacker installs a "Synthetic GNSS" driver.
- **Action**: The driver feeds NMEA sentences (location data) into the OS Location Service.
- **Complexity**: Sophisticated malware can sign these drivers to pass low-level kernel integrity checks.
- **Result**: The OS processes the synthetic data as genuine satellite signals.

### Vector C: Mock Location Provider
- **Method**: Leverages Android "Developer Options" or system-level configuration.
- **Action**: Toggles the `ALLOW_MOCK_LOCATION` flag.
- **Result**: The system broadasts the mock provider as the primary source of truth.

---

## 3. Aegis Defense: Multi-Factor Provenance (MFP)

AegisSovereignAI defends against these threats by shifting trust from the OS APIs to **Hardware-Rooted Sensor Fusion**.

### Layer 1: Mobile Sensor Sidecar (Raw Data Ingress)
Instead of requesting "Coordinates" from the OS, Aegis requests **Raw Sensor Footprints**:
- **Cell Tower Triangulation**: Real-time CID/LAC data.
- **WiFi Proximity**: Known BSSID fingerprints of authorized branches or secure enterprise infrastructure.
- **NTP Skew**: Measuring network delay to US-based sync servers.

### Layer 2: Hardware-Rooted EAT Binding
The Aegis app triggers a **Point-in-Time Attestation** via the **Secure Enclave/StrongBox**:
1.  **Nonce Generation**: Aegis Cloud sends a cryptographically random challenge.
2.  **Hardware Signing**: The Secure Enclave signs the **Challenge + Raw Sensor Data**.
3.  **Integrity Proof**: The signature includes a proof that **Root/Jailbreak** status is negative.

### Layer 3: ZKP Verification (Privacy-Preserving Proof)
The device generates a **Zero-Knowledge Proof (ZKP)**:
- **Verification**: The **Aegis Verifier**—acting as the Trust Bridge—validates the proof without seeing raw PII. If the sensor data was synthetic (Missing Cell/WiFi correlation), the mathematical proof fails.
- **Enforcement (The SVID Grant)**: Upon successful verification, the **Aegis Control Plane** issues a **Unified Workload SVID** containing the `grc.geolocation.status: compliant` claim.

---

## 4. Residual Risk Analysis

| Risk | Mitigation |
| :--- | :--- |
| **SDR Location Spoofing** | Mitigated by **Multi-Factor** (WiFi/Cell) cross-referencing. |
| **Hardware Compromise** | Out of scope; we assume the **Silicon Root of Trust** (Apple SE/Qualcomm TEE) is intact. |
| **Zero-Day Hooking** | Mitigated by **Runtime SVID Revocation** triggered by Linux IMA / App Attest signals. |

**Verdict**: By moving the security boundary from the OS APIs to the **Hardware Secure Enclave** and enforcing it via the **Unified Identity Plane (SVID)**, AegisSovereignAI makes infrastructure blind spots mathematically visible and cryptographically unenforceable at the API Gateway.
