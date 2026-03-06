<!-- Version: 0.2.0 | Last Updated: 2026-01-11 -->
# AegisSovereignAI: Sovereign Hybrid Cloud PoC
**Hardware-rooted Unified Identity for Sovereign Cloud — Verifiable Data Sovereignty across Public and On-Premise Infrastructure**

> **Reference Implementation** — This architecture and codebase serves as a reference implementation for the [IETF WIMSE Verifiable Geo-Fence draft](https://datatracker.ietf.org/doc/draft-lkspa-wimse-verifiable-geo-fence/), demonstrating Hardware-to-Workload trust using TPM 2.0, SPIRE, Keylime, and Zero-Knowledge Proofs.

This Proof of Concept implements the **AegisSovereignAI** architecture to create a contiguous Chain of Trust between a public cloud and a sovereign private cloud (on-premise).

## Quick Start

> **Minimum requirement:** One Linux machine with hardware TPM 2.0 (`ls /dev/tpm*` to verify).
> Ubuntu 22.04 LTS recommended; RHEL/Fedora users should install packages manually (see [Appendix](#appendix)).

```bash
git clone https://github.com/lfedgeai/AegisSovereignAI.git
cd AegisSovereignAI/hybrid-cloud-poc
./run-demo.sh
```

That's it. This single command will:
1. **Install** missing OS dependencies (Go, Rust, Python, TPM tools)
2. **Cleanup** any previously running services
3. **Build** SPIRE, Keylime, ZKP prover, and WASM filters
4. **Start** all services and run integration tests
5. **Run** the demo (interactive — press Enter between acts)

**Options:**
```bash
./run-demo.sh --auto        # Fully unattended, end to end
./run-demo.sh --speed       # Shorter demo (~7 min)
./run-demo.sh --skip-build  # Reuse existing binaries
```

All services default to `localhost`. For multi-machine setups, override via environment variables:
```bash
CONTROL_PLANE_HOST=10.1.0.11 AGENTS_HOST=10.1.0.11 ONPREM_HOST=10.1.0.10 ./run-demo.sh
```

**Slides:** [View Presentation](https://onedrive.live.com/?id=746ADA9DC9BA7CB7%21sa416cb345794427ab085a20f8ccc0edd&cid=746ADA9DC9BA7CB7&redeem=aHR0cHM6Ly8xZHJ2Lm1zL2IvYy83NDZhZGE5ZGM5YmE3Y2I3L0VUVExGcVNVVjNwQ3NJV2lENHpNRHQwQlh6U3djQ01HWDhjQS1xbGxLZm1Zdnc%5FZT1PTnJqZjE&parId=746ADA9DC9BA7CB7%21s95775661177f4ef5a4ba84313cd3795a&o=OneUp)

## The Architecture Scenario
This PoC simulates a real-world regulated environment:
- **The Public Zone (Public Cloud - e.g., Telefonica):** Represents a scalable environment where initial processing occurs (the Client).
- **The Trusted Zone (On-Premise):** Represents the Private Sovereign Cloud where the Root of Trust is established and sensitive, regulated data (e.g., Banking or Healthcare Secrets) is stored (the Server).
- **The Trust Bridge (AegisSovereignAI):** A unified control plane that issues short-lived, hardware-rooted credentials allowing the two zones to communicate only if strict integrity and location policies are met.

## The Problem
Current security approaches for AI inference applications, secret stores, system agents, and model repositories face **critical gaps** that are amplified in edge AI deployments. The traditional security model relies on bearer tokens, proof-of-possession tokens, and IP-based geofencing, which are vulnerable to replay attacks, account manipulation, and location spoofing.

![The Problem: A Fragile and Non-Verifiable Security Model](images/Slide6.PNG)

The diagram illustrates a traditional security architecture for AI inference applications showing:
1. End user host sending inference data with bearer tokens and source IP to a high-compliance application (e.g., a Private Wealth app for **High-Net-Worth Clients**) in Sovereign Cloud
2. Workload host requesting secrets from Customer-managed key vault using bearer/proof-of-possession tokens
3. Key vault retrieving encrypted models from storage

The diagram highlights three critical security challenges:
- **Host-Affinity Realization Challenges**: Bearer token replay, proof-of-possession token vulnerabilities to orchestration/RBAC abuse
- **Geolocation-Affinity Realization Challenges**: IP-based geofencing bypass via VPNs/proxies
- **Static and Isolated Security Challenges**: Non-verifiable monitoring systems

## The Solution: The Sovereign Trust Loop
Our solution provides a **Unified Identity & Trust Framework** that secures the entire AI lifecycle. By binding workload identity, host hardware integrity, and verifiable geolocation into a single cryptographic credential, we satisfy the requirements for Ingress, Processing, and Egress. **Privacy-preserving geofencing** using Zero-Knowledge Proofs ensures location compliance without exposing raw GPS data or infrastructure topology—delivering mathematical certainty to regulators while preserving user and enterprise privacy.

![The Solution: A Zero-Trust, HW-Rooted, Unified, Extensible & Verifiable Identity](images/Slide7.PNG)

A "Sovereign" system that only secures the input or output is a broken chain. For Tier-1 financial institutions, trust must be established at the source, maintained in the cloud, and verified at the edge.

1.  **Verified Ingress**: Hardware-rooted attestation of the originating client device ensuring data provenance and **Regulation K (Reg-K)** geographic compliance via **privacy-preserving techniques** (e.g., Zero-Knowledge Proofs / ZKPs).
    *   *Customer Value:* **Radical Privacy**—verify compliance without tracking movement history.
2.  **Trusted Processing**: Confidential Computing (TEEs) and Platform Integrity (Keylime) ensuring the AI workload is isolated from the cloud infrastructure.
    *   *Customer Value:* **Absolute Data Sovereignty**—ensuring personal financial data is never exposed to third-party infrastructure.
3.  **Verifiable Egress**: Hardware-rooted verification ensuring insights are released only to identity-verified and geofenced endpoints.
    *   *Customer Value:* **Security of Outcome**—guaranteeing that sensitive financial insights are delivered only to the authorized user's verified device.

### The Privacy-Preserving Story: Compliance without Tracking

A core pillar of AegisSovereignAI is **Privacy-Preserving Geofencing**. Traditional geofencing relies on capturing and storing raw GPS coordinates, which creates a significant privacy risk and tracking liability.

AegisSovereignAI solves this by implementing **Zero-Knowledge Proof (ZKP) Geofencing** for both ingress and egress:

#### Ingress (User Device → Sovereign Cloud)
- **Prover-Side (User Device)**: The Geolocation Sidecar generates a Zero-Knowledge Proof that the device is within an authorized zone.
- **Verifier-Side (Sovereign Cloud)**: The verifier validates the proof's mathematical correctness without ever seeing, storing, or processing the raw latitude and longitude.
- **Customer Value**: Users can prove they are in a compliant region (e.g., EU/EEA for Reg-K) without exposing their precise location.

#### Egress (Data Center → User/External System)
- **Prover-Side (Data Center Workload)**: The AI workload or server proves it is operating within an authorized data sovereignty zone (e.g., "on-prem in NYC" or "Equinix Madrid").
- **Verifier-Side (Policy Engine/Gateway)**: The Envoy gateway or policy engine validates the ZKP before releasing sensitive data or PII.
- **Customer Value**: Enterprises can cryptographically prove data residency compliance to regulators without exposing infrastructure topology.

**The Result**: Total privacy for users and enterprises, with mathematical certainty for regulators. Location is verified at both ingress and egress, but raw movement history or infrastructure details are never created.

---

## Demo Acts

> **One command, ~7 minutes, real hardware:**
> ```bash
> ./run-demo.sh
> ```
> Press Enter between acts to proceed. See [Demo Options](#demo-options) in the Appendix for unattended and deep-dive modes.

### Environment

The demo runs on **physical Linux machines** with hardware TPM 2.0 (or a single machine for localhost deployment):

| Zone | Role | Services |
|------|------|----------|
| **Control Plane — Cloud** | Identity authority | Keylime Verifier & Registrar, SPIRE Server |
| **API Gateway — Cloud** | Zero-trust network access | Envoy proxy (WASM plugin), Key Vault (Server App) |
| **Sovereign Edge — Bare Metal** | Location anchor + workload host | Keylime Agent, SPIRE Agent, SPIRE TPM Plugin, Geolocation Sidecar¹, Inference App (Client App), TPM, Mobile Location Sensor |

> [!NOTE]
> ¹ The **Geolocation Sidecar** (mobile-sensor-microservice, port 9050) runs alongside the Keylime Agent on the edge host. It invokes the Plonky2 ZKP prover to generate sovereignty receipts from sensor data. This component is not shown in the architecture slide but is integral to the ZKP attestation pipeline. In single-machine deployments, all zones run on `localhost`.

---

### Act 1 — Trusted Infrastructure Setup



`run-demo.sh` starts all services on both machines. You'll see each service start with a green `✓`:

| Step | What you see | Why it matters |
|------|-------------|----------------|
| SPIRE Server starts | Trust root is online | All workload identities are issued from this single root CA |
| Keylime Verifier starts | Attestation engine is online | Will continuously verify TPM quotes from every agent |
| Envoy + WASM filter starts | API gateway is online | Will enforce geolocation policy on every request at wire speed |
| Geolocation Sidecar starts | ZKP prover is ready | Plonky2 circuit loaded, ready to generate geofence proofs |

**Value:** Nothing is trusted by default. Every component must prove its identity before it can participate.

---

### Act 2 — The Happy Path (Proof of Geofencing)


The agents join the trust fabric and a workload makes an mTLS request through the gateway. This is the full **Hardware → Workload → Gateway** chain:

| Step | What you see | Why it matters |
|------|-------------|----------------|
| Keylime Agent starts | TPM quote accepted ✓ | Physical hardware is verified — not a VM, not tampered |
| SPIRE Agent attests | Unified SVID issued ✓ | Workload identity now carries geolocation + TPM claims |
| ZKP proof generated | `sovereignty_receipt` embedded | Location verified *without* raw GPS ever leaving the device |
| mTLS client connects | `200 OK` through Envoy | WASM filter validated the ZKP proof hash + geolocation claims |
| SVID claims inspected | Attested claims JSON printed | Audit trail: sensor ID + proof hash logged, no PII stored |

**Value:** An auditor (e.g., OCC) can verify the workload was in a compliant geography *without the enterprise ever ingesting raw location data*. This solves the Reg-K vs. GDPR deadlock.

---

### Act 3 — ZKP Deep Dive (Proof Without Knowing)


The demo extracts the ZKP proof from the workload's SVID and verifies it independently, then attempts a **tamper attack**:

| Step | What you see | Why it matters |
|------|-------------|----------------|
| Proof extracted | `sovereignty_receipt` retrieved from Keylime | The geofence proof was embedded during attestation |
| Plonky2 verifier runs | **Proof VALID** ✓ | Circuit confirms device is inside geofence — without learning GPS coordinates |
| Public inputs shown | `center_lat`, `center_lon`, `radius`, `idhash` | Verifier sees *policy* (the fence) + *device binding* (SHA-256 of TPM AK), never raw location |
| Private inputs hidden | `██████████` | Device latitude/longitude never leave the proof — this is the ZKP core value |
| Tamper attack | Attacker changes `idhash` to `999999999` | Attempting to transplant the proof to a different device |
| Tamper rejected | **Proof INVALID: public inputs mismatch** | Proof is cryptographically bound to a specific TPM — cannot be reused on another machine |

> [!TIP]
> **The `--full` demo** (~20 min) additionally includes the **Rogue Admin** scenario: physically disconnecting the USB sensor to demonstrate fail-closed degraded SVIDs and automatic self-healing.

**Value:** An auditor can verify the workload was in a compliant geography without ever seeing GPS coordinates. The proof is bound to specific hardware — it cannot be forged, replayed, or transplanted.

---

## Architecture Deep-Dive

For a concise end-to-end walkthrough of the trust chain as implemented, see:

👉 **[End-to-End Flow: Hardware → Workload → Gateway](README-arch-sovereign-unified-identity.md#end-to-end-flow-hardware-workload-gateway)**

For the complete technical spec (all phases, code-level detail):

👉 **[Unified Identity & Trust Framework](README-arch-sovereign-unified-identity.md)**

![Hybrid Cloud Unified Identity PoC End-to-End Solution Architecture](images/Slide19.PNG)

---

## Appendix

### Demo Options

| Flag | Behaviour | Duration |
|------|-----------|---------|
| *(default)* | Interactive — press Enter between acts | ~7 min |
| `--auto` | Fully unattended, no pauses | ~7 min |
| `--full` | Deep-dive with ZKP internals | ~20 min |

```bash
./run-demo.sh --auto       # Unattended
./run-demo.sh --full       # Full version
```

### Troubleshooting

**Unified Identity - SVID missing geolocation claims:**
- Verify Keylime Verifier has verified the agent: `curl -k https://localhost:8881/v2.1/agents/`
- Check `unified_identity_enabled: true` is set in both `spire-server.conf` and `spire-agent.conf`.
- Ensure the Geolocation Sidecar is reachable from the Keylime Agent.

**Delegated Certification failing (Task 14b):**
- Verify the TPM Plugin Server is using HTTPS (mTLS) to talk to the rust-keylime agent.
- Check for "JSON format mismatch" in `/tmp/tpm-plugin-server.log`.
- Ensure `agent_uuid` in the attestation request matches the one registered in Keylime.

**mTLS Handshake Errors (Envoy/Client):**
- **Clock Drift**: Ensure all machines have synchronized time: `sudo ntpdate pool.ntp.org`.
- **Bundle Mismatch**: Verify Envoy has the latest SPIRE bundle: `openssl x509 -in /opt/envoy/certs/spire-bundle.pem -text -noout`.
- **WASM Fail-Closed**: If the WASM filter cannot reach the Geolocation Sidecar, it will block connections with a 403. Check `/opt/envoy/logs/envoy.log` for upstream connection errors.

**SPIRE Agent not attesting:**
- Check TPM is accessible: `ls -la /dev/tpm*`
- Verify TPM Plugin Server is running: `ps aux | grep tpm-plugin`
- Check SPIRE Agent logs: `tail -f /tmp/spire-agent.log`

**Envoy not verifying certificates:**
- Verify SPIRE bundle exists: `ls -la /opt/envoy/certs/spire-bundle.pem`
- Check Envoy config: `sudo envoy --config-path /opt/envoy/envoy.yaml --mode validate`

**Geolocation Sidecar failing:**
- Check CAMARA core credentials in the mapping database (not environment variables in production).
- Verify sensor ID in database: `sqlite3 mobile-sensor-microservice/sensor_mapping.db "SELECT * FROM sensor_map;"`

**Client connection fails:**
- Verify Envoy certificate is copied: `ls -la ~/.mtls-demo/envoy-cert.pem`
- Check firewall rules: `sudo iptables -L -n | grep 8080`
- Verify SPIRE Agent socket: `ls -la /tmp/spire-agent/public/api.sock`

## Governance, Compliance & Standards

AegisSovereignAI aligns with global standards (IETF RATS, WIMSE) to provide a cryptographically verifiable **Silicon-to-Audit** trail for regulated AI workloads.

For details on regulatory mapping (Reg-K, OCC 2021-19), IETF draft alignment, and hardware trust scaling (RIM/OEM Manifests), see:

👉 **[Governance, Compliance & Standards (Architecture Doc)](README-arch-sovereign-unified-identity.md#governance-compliance-standards)**

> **Note:** The custom X.509 extension OID `1.3.6.1.4.1.55744.1.1` used for Unified Identity attestation claims is under a temporary IANA Private Enterprise Number request (tracking: [PHE1-CSY-PJ5](https://www.iana.org/requests/phe1-csy-pj5/)). The OID will be updated once IANA assigns a permanent enterprise number.

## Components

### SPIRE
- **Server**: Issues SVIDs with attested claims
- **Agent**: Provides Workload API to applications
- **TPM Plugin**: Integrates TPM attestation with SPIRE
- **Open Source**: [SPIRE Project](https://spiffe.io/spire/)
- Location: `spire/`

### Keylime
- **Verifier**: Validates TPM attestation
- **Registrar**: Stores agent registration information
- **Agent**: Provides TPM attestation to SPIRE
- **Open Source**: [Keylime Project](https://keylime.dev/)
- Location: `keylime/` and `rust-keylime/`

### Python Applications
- **Client**: mTLS client using SPIRE SVIDs
- **Server**: mTLS server for testing
- Location: `python-app-demo/`

### Enterprise Private Cloud
- **Envoy Proxy**: mTLS termination and routing
- **WASM Filter**: Sensor ID extraction and verification
- **Geolocation Sidecar**: CAMARA API integration, ZKP proof generation
- **Open Source**: [Envoy Proxy](https://www.envoyproxy.io/)
## Documentation

- **[End-to-End Sovereign Unified Identity & Trust Framework](README-arch-sovereign-unified-identity.md)**: The core technical spec for Stage 1 (Verified Ingress) and the Unified Identity pipeline.
- [Enterprise Private Cloud README](enterprise-private-cloud/README.md) - Detailed setup and architecture
- [Python App Demo README](python-app-demo/README.md) - Client/server usage
- [test_agents.sh](test_agents.sh) - Agent services integration test script
- [test_control_plane.sh](test_control_plane.sh) - Control plane services test script
- [test_integration.sh](test_integration.sh) - Complete integration test script

## Logs

### Log File Locations

**Control Plane Host:**
- SPIRE Server: `/tmp/spire-server.log`
- SPIRE Agent: `/tmp/spire-agent.log`
- Keylime Verifier: `/tmp/keylime-verifier.log`
- rust-keylime Agent: `/tmp/rust-keylime-agent.log`
- TPM Plugin Server: `/tmp/tpm-plugin-server.log`

**On-Prem Host:**
- Envoy: `/opt/envoy/logs/envoy.log` (requires sudo)
- mTLS Server: `/tmp/mtls-server.log`
- Geolocation Sidecar: `/tmp/mobile-sensor.log`

### Watch Logs During Demo

For monitoring logs during a demo, use the watch scripts:

**Option 1: Individual terminal windows**
```bash
cd enterprise-private-cloud

# Terminal 1 - Envoy logs
./watch-envoy-logs.sh

# Terminal 2 - mTLS server logs
./watch-mtls-server-logs.sh

# Terminal 3 - Mobile sensor service logs
./watch-mobile-sensor-logs.sh
```

**Option 2: Single tmux session (all logs in one window)**
```bash
cd enterprise-private-cloud
./watch-all-logs.sh
```

This creates a tmux session with 3 panes showing all logs simultaneously.

