<!-- Version: 0.2.0 | Last Updated: 2026-01-11 -->
# Sovereign Hybrid Cloud PoC
**Demonstrating Verifiable Data Sovereignty across Public Cloud (e.g., Telefonica) and On-Premise Infrastructure**

This Proof of Concept implements the **AegisSovereignAI** architecture to create a contiguous Chain of Trust between a public cloud and a sovereign private cloud (on-premise).

## Overview

This directory contains a proof-of-concept implementation demonstrating sovereign hybrid cloud unified identity with hardware-rooted verifiable geofencing and residency proofs using SPIRE, Keylime, and Envoy. This POC addresses the challenges of the traditional non-verifiable security model by providing cryptographically verifiable proofs that bind workload identity, host integrity, and geolocation into unified credentials.

**Slides:** [View Presentation](https://onedrive.live.com/?id=746ADA9DC9BA7CB7%21sa416cb345794427ab085a20f8ccc0edd&cid=746ADA9DC9BA7CB7&redeem=aHR0cHM6Ly8xZHJ2Lm1zL2IvYy83NDZhZGE5ZGM5YmE3Y2I3L0VUVExGcVNVVjNwQ3NJV2lENHpNRHQwQlh6U3djQ01HWDhjQS1xbGxLZm1Zdnc%5FZT1PTnJqZjE&parId=746ADA9DC9BA7CB7%21s95775661177f4ef5a4ba84313cd3795a&o=OneUp)

## The Architecture Scenario
This PoC simulates a real-world regulated environment:
- **The Public Zone (Public Cloud - e.g., Telefonica):** Represents a scalable environment where initial processing occurs (the Client).
- **The Trusted Zone (On-Premise):** Represents the Sovereign Private Cloud where the Root of Trust is established and sensitive data (e.g., Banking Secrets) is stored (the Server).
- **The Trust Bridge (AegisSovereignAI):** A unified control plane that issues short-lived, hardware-rooted credentials allowing the two zones to communicate only if strict integrity and location policies are met.

## The Problem

Current security approaches for AI inference applications, secret stores, system agents, and model repositories face **critical gaps** that are amplified in edge AI deployments. The traditional security model relies on bearer tokens, proof-of-possession tokens, and IP-based geofencing, which are vulnerable to replay attacks, account manipulation, and location spoofing.

![The Problem: A Fragile and Non-Verifiable Security Model](images/Slide6.PNG)

The diagram illustrates a traditional security architecture for AI inference applications showing:
1. End user host sending inference data with bearer tokens and source IP to Bank Inference application in Sovereign Cloud
2. Workload host requesting secrets from Customer-managed key vault using bearer/proof-of-possession tokens
3. Key vault retrieving encrypted models from storage

The diagram highlights three critical security challenges:
- **Host-Affinity Realization Challenges**: Bearer token replay, proof-of-possession token vulnerabilities to orchestration/RBAC abuse
- **Geolocation-Affinity Realization Challenges**: IP-based geofencing bypass via VPNs/proxies
- **Static and Isolated Security Challenges**: Non-verifiable monitoring systems

## The Solution: The Sovereign Trust Loop

Our solution provides a **Unified Identity & Trust Framework** that secures the entire AI lifecycle. By binding workload identity, host hardware integrity, and verifiable geolocation into a single cryptographic credential, we satisfy the requirements for Ingress, Processing, and Egress.

![The Solution: A Zero-Trust, HW-Rooted, Unified, Extensible & Verifiable Identity](images/Slide7.PNG)

### The Sovereign Trust Loop
A "Sovereign" system that only secures the output is a broken chain. For Tier-1 financial institutions, trust must be established at the source, maintained in the cloud, and verified at the edge.

1.  **Verified Ingress**: Hardware-rooted attestation of the originating client device ensuring data provenance and **Regulation K (Reg-K)** geographic compliance via **privacy-preserving techniques** (e.g., Zero-Knowledge Proofs / ZKPs).
    *   *Customer Value:* **Radical Privacy**—verify compliance without tracking movement history.
2.  **Trusted Processing**: Confidential Computing (TEEs) and Platform Integrity (Keylime) ensuring the AI workload is isolated from the cloud infrastructure.
    *   *Customer Value:* **Absolute Data Sovereignty**—ensuring personal financial data is never exposed to third-party infrastructure.
3.  **Verifiable Egress**: Hardware-rooted verification ensuring insights are released only to identity-verified and geofenced endpoints.
    *   *Customer Value:* **Security of Outcome**—guaranteeing that sensitive financial insights are delivered only to the authorized user's verified device.

## Enterprise Use Cases

This PoC demonstrates the technical implementation for the 4 enterprise use cases described in the [main AegisSovereignAI README](../README.md#enterprise-sovereign-use-cases-focus-financial-services):

1. **Enterprise Customer** - Private Wealth Gen-AI Advisory (Unmanaged Devices)
2. **Enterprise Employee** - Secure Remote Branch Operations  
3. **Enterprise Tenant** - Secure Sandboxing for Line-of-Business (LOB) units
4. **Regulator** - Automated Regulatory Audit

For full use case descriptions, value propositions, and regulatory context, see the [main README](../README.md).

### PoC Implementation Coverage

This PoC provides end-to-end implementation for **Stage 2: Trusted Egress & Data Center Infrastructure Attestation**. Stage 1 (Verified Ingress) is defined architecturally in [README-arch-sovereign-ingress.md](README-arch-sovereign-ingress.md).

| Use Case | Stage 1: Verified Ingress | Stage 2: Trusted Egress | PoC Status |
|----------|---------------------------|-------------------------|------------|
| **Enterprise Customer** | Roadmap (Ingress architecture defined) | ✅ Implemented | Partial - Egress ready |
| **Enterprise Employee** | Roadmap (Ingress architecture defined) | ✅ Implemented | Partial - Egress ready |
| **Enterprise Tenant** | N/A (Internal workload isolation) | ✅ Implemented | Full |
| **Regulator** | Roadmap (Ingress architecture defined) | ✅ Implemented | Partial - Data center audit ready |

**What This PoC Currently Demonstrates:**
- ✅ Hardware-rooted identity (TPM attestation via Keylime)
- ✅ Unified SPIFFE/SPIRE identity with geolocation claims (sensor metadata in SVID)
- ✅ Envoy-based policy enforcement (fail-closed WASM filtering)
- ✅ Degraded SVID detection (insider threat protection)
- ✅ mTLS with hardware-bound certificates (workload attestation)

**Roadmap (Architecturally Defined):**
- 🔲 Privacy-preserving geofencing (ZKP-based Reg-K compliance without storing GPS) - [Architecture](README-arch-sovereign-ingress.md)
- 🔲 Privacy-preserving data center audit trail (batch & purge proofs) - See main [README](../README.md#layer-3-ai-governance-verifiable-logic--privacy)

---

## Operational Implementation Details
The AegisSovereignAI framework implements this loop through:
- **Workload Identity Manager** (SPIRE Server) and **Host Identity/Policy Manager** (Keylime) for continuous attestation
- Cryptographic binding of workload identity, host hardware identity (TPM), platform policy, and location hardware identity (GNSS/mobile sensor) into unified SVIDs
- Replacement of fragile bearer tokens with hardware-rooted **Proof of Residency (PoR)**, **Proof of Geofencing (PoG)**, and **Zero-Knowledge Proofs (ZKP)** (Gen 4).
- **Standardization Alignment**: Explicit alignment with **IETF WIMSE (Workload Identity in Multi-Service Environments)**, specifically **`draft-lkspa-wimse-verifiable-geo-fence`**, and **IETF RATS (Remote Attestation Procedures)**. This ensures interoperability with emerging global standards for hardware-rooted geofencing and verifiable proof of residency.
- **LOB Multi-Tenancy**: This framework enables cryptographically enforced multi-tenancy, ensuring that a Mortgage AI workload cannot access Credit Card data even when running on shared sovereign hardware.

> [!NOTE]
> **Implementation Status**: The Verified Ingress (Stage 1) architecture is defined and the technical implementation is slated for the immediate roadmap. This PoC currently provides the end-to-end implementation for the Trusted Egress (Stage 2).

## Stage 1: Verified Ingress (Roadmap)
The AegisSovereignAI framework treats the trust chain as a closed loop. For a detailed technical breakdown of the Ingress hardware-rooted provenance, see:

👉 **[README-arch-sovereign-ingress.md](README-arch-sovereign-ingress.md)**

## Stage 2: Trusted Egress & Data Center Infrastructure Attestation (Upstream Ready)

The current PoC implementation provides a complete, **upstream-ready** integration demonstrating **Egress Unified Identity**. This stage secures the **Managed Data Center Infrastructure** (Sovereign Cloud) by ensuring that the on-premise servers and AI workloads are attested before they can release sensitive egress data. This provides the "Server-Side" mathematical proof required for **Use Case 4 (Automated Regulatory Audit)**.

### Unified Identity Architecture
For detailed information on the unified identity architecture, including the complete end-to-end flow, attestation mechanisms, and component interactions, see:
**[README-arch-sovereign-unified-identity.md](README-arch-sovereign-unified-identity.md)**

### Architecture Overview

**Sovereign Cloud Or Edge Cloud (Client Side):**
- **Control Plane Identity Services:**
  - Host Identity (Keylime Verifier & Registrar)
  - Workload Identity (SPIRE Server)
- **Agents and Plugins:**
  - Keylime Agent
  - SPIRE Agent
  - SPIRE TPM Plugin
- **Client Application:**
  - Client App using unified identity
- **Hardware/Sensors:**
  - Mobile location sensor (e.g., USB tethered smartphone)
  - TPM (Trusted Platform Module)

**Customer on-Prem Private Cloud (Server Side):**
- **Gateway and Application:**
  - Envoy (API Gateway) with WASM plugin
  - Server App
- **Geolocation Service:**
  - Mobile Geolocation Service (CAMARA - Common API framework for Mobile network Acceleration and Reachability APIs)

![Hybrid Cloud Unified Identity PoC End-to-End Solution Architecture](images/Slide19.PNG)

**Sovereign Cloud/Edge Cloud (left, orange boundary):**
- Control Plane Identity Services: Host Identity (Keylime Verifier & Registrar), Workload Identity (SPIRE Server)
- Agents and Plugins: Keylime Agent, SPIRE Agent, SPIRE TPM Plugin, Mobile location sensor (USB tethered smartphone), TPM, and Client App using unified identity (SPIRE SVID)
- System flow: SPIRE agent gets/refreshes unified identity with TPM-attested geolocation from SPIRE server
- Client App flow: Client app inherits unified identity from SPIRE server – agent SVID included in certificate chain for claim inheritance

**Customer on-Prem Private Cloud (right, blue boundary):**
- Contains: Envoy (API Gateway) with WASM plugin, Server App, and Mobile Geolocation Service (CAMARA API)
- System flow: Envoy verifies unified identity signature using configured SPIRE server public key cert and verifies geolocation through Mobile Geolocation Service
- Server App flow: Envoy communicates to Server App using standard mTLS

- [Unified Identity Architecture](README-arch-sovereign-unified-identity.md) - Includes detailed **Observability & Metrics** configuration

### Implementation Scope

> [!IMPORTANT]
> The following Quick Start Guide and the associated code provide the full end-to-end implementation for **Stage 2: Egress Unified Identity**. This includes the hardware-rooted identity bridge between Sovereign and Private clouds. **Stage 1: Ingress Unified Identity** is currently defined as an architectural roadmap.

## Quick Start Guide

This section provides a step-by-step guide to set up and run the complete hybrid cloud unified identity demonstration.

### Prerequisites

For a smooth installation, your system should meet the core requirements:
- **OS**: Ubuntu 22.04 LTS (recommended)
- **Hardware**: Two machines with static IPs, TPM 2.0 (hardware or software)
- **Toolchains**: Python 3.10+, Go 1.22+, Rust 1.92+

A comprehensive helper script is provided to automate the installation of all system packages, toolchains, and configurations:
👉 **[`install_prerequisites.sh`](install_prerequisites.sh)**

#### Installation Scripts
Two helper scripts are provided to simplify setup:

1. **`check_packages.sh`** - Check installed packages and versions:
   ```bash
   ./check_packages.sh              # Check local system
   ./check_packages.sh 10.1.0.10    # Check remote system via SSH
   ```

2. **`install_prerequisites.sh`** - Install all required packages:
   ```bash
   ./install_prerequisites.sh              # Install on local system
   ./install_prerequisites.sh 10.1.0.10     # Install on remote system via SSH
   ```

**Note:** The installation script will:
- Update package lists
- Install all required Linux packages
- Install/update Rust toolchain (if not present)
- Install/update Go toolchain (if not present or version < 1.20)
- Install required Python packages
- Set up TSS group and add user to it

**Important:** After running the installation script, you may need to:

1. **For Rust:** Run `source $HOME/.cargo/env` or add to `~/.bashrc`:
   ```bash
   echo 'source $HOME/.cargo/env' >> ~/.bashrc
   ```

2. **For Go:** Ensure `/usr/local/go/bin` is in your PATH. Add to `~/.bashrc`:
   ```bash
   echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
   ```

3. **For TSS group:** Log out and back in if you were added to the `tss` group

4. **Reload shell configuration:**
   ```bash
   source ~/.bashrc
   ```

5. **Verify installation:**
   ```bash
   ./check_packages.sh
   ```



### Installation Steps

#### Step 1: Check Current Package Status

Before installing, check what's already installed:

```bash
# Check local system
./check_packages.sh

# Check remote system (if needed)
./check_packages.sh 10.1.0.10
```

#### Step 2: Install Prerequisites

Install all required packages using the automated script:

```bash
# Install on local system
./install_prerequisites.sh

# Install on remote system via SSH
./install_prerequisites.sh 10.1.0.10
```

**Note:** The installation script requires sudo access and will prompt for your password.

#### Step 3: Post-Installation Configuration

After installation, configure your environment:

```bash
# Add Rust to PATH (if Rust was just installed)
echo 'source $HOME/.cargo/env' >> ~/.bashrc

# Add Go to PATH (if Go was just installed/updated)
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc
```

**Important:** If you were added to the `tss` group during installation, **log out and back in** for the group changes to take effect. This is required for TPM access.

#### Step 4: Verify Prerequisites

Ensure all prerequisites are installed correctly:

```bash
# Verify system packages
dpkg -l | grep -E "(tpm2|swtpm|libtss2|libssl-dev|python3-dev|build-essential|libclang)"

# Verify toolchains
python3 --version    # Should show 3.10+
rustc --version      # Should show 1.91+ (if installed)
go version           # Should show go1.22+ (if installed)

# Verify Python packages
python3 -m pip list | grep -E "(spiffe|cryptography|grpcio|protobuf)"

# Verify TPM access
groups | grep tss    # Should show tss group
```

#### Step 5: Build SPIRE and Keylime Components

After prerequisites are installed, build the required components (if not already built):

```bash
# Build SPIRE server and agent
cd spire
make bin/spire-server bin/spire-agent
cd ..

# Build rust-keylime agent
cd rust-keylime
cargo build --release
cd ..
```

**Note:** Building SPIRE and rust-keylime may take several minutes the first time. Subsequent builds will be faster due to caching.

#### Troubleshooting Installation

If you encounter issues during installation:

**Rust not found after installation:**
```bash
source $HOME/.cargo/env
```

**Go not found after installation:**
```bash
export PATH=$PATH:/usr/local/go/bin
```

**TPM access denied:**
1. Verify user is in `tss` group: `groups | grep tss`
2. If not, add user: `sudo usermod -a -G tss $USER`
3. **Log out and back in** (required)
4. Verify TPM device: `ls -l /dev/tpm*`

**Python packages not found:**
```bash
python3 -m pip install --upgrade pip
python3 -m pip install spiffe cryptography grpcio protobuf requests
```

### Port Configuration

This section documents all port numbers used by the test scripts. All ports are unique with no conflicts between hosts.

#### On 10.1.0.11 (Sovereign Cloud/Edge Cloud)

**Started by `test_control_plane.sh`:**
- **8881** - Keylime Verifier (HTTPS)
- **8890** - Keylime Registrar (HTTP)
- **8891** - Keylime Registrar (HTTPS/TLS)
- **9050** - Mobile Sensor Microservice (used by control plane for location verification)

**Started by `test_agents.sh`:**
- **9002** - rust-keylime Agent (HTTP/HTTPS)
- **8081** - SPIRE Server (mentioned in health checks, uses Unix socket for API)

**Note:** SPIRE Server and SPIRE Agent primarily use Unix domain sockets (`/tmp/spire-server/private/api.sock` and `/tmp/spire-agent/public/api.sock`) rather than TCP ports for their primary API.

#### On 10.1.0.10 (Customer On-Prem Private Cloud)

**Started by `test_onprem.sh`:**
- **5000** - Mobile Location Service (HTTP)
- **9443** - mTLS Server (HTTPS)
- **8080** - Envoy Proxy (HTTP/HTTPS)

#### Port Summary Table

| Port | Service | Host | Script | Protocol |
|------|---------|------|--------|----------|
| 5000 | Mobile Location Service | 10.1.0.10 | test_onprem.sh | HTTP |
| 8080 | Envoy Proxy | 10.1.0.10 | test_onprem.sh | HTTP/HTTPS |
| 8081 | SPIRE Server | 10.1.0.11 | test_agents.sh | Unix Socket (health checks) |
| 8881 | Keylime Verifier | 10.1.0.11 | test_control_plane.sh | HTTPS |
| 8890 | Keylime Registrar | 10.1.0.11 | test_control_plane.sh | HTTP |
| 8891 | Keylime Registrar | 10.1.0.11 | test_control_plane.sh | HTTPS |
| 9002 | rust-keylime Agent | 10.1.0.11 | test_agents.sh | HTTP/HTTPS |
| 9050 | Mobile Sensor Microservice | 10.1.0.11 | test_control_plane.sh | HTTP |
| 9443 | mTLS Server | 10.1.0.10 | test_onprem.sh | HTTPS |

**Port Conflict Analysis:** ✅ No conflicts detected. All ports are unique and assigned to different services on different hosts.

### Demo Act 1: Trusted Infrastructure Setup

*See Slide 19 for the architecture diagram*

**SOVEREIGN PUBLIC/EDGE CLOUD CONTROL PLANE WINDOW:** (e.g., 10.1.0.11)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc
./test_control_plane.sh --no-pause

# Verify processes are running
ps -aux | grep spire-server
ps -aux | grep keylime.cmd.verifier
ps -aux | grep keylime.cmd.registrar

# Health checks (optional but recommended)
# Check SPIRE Server health
./spire/bin/spire-server healthcheck -socketPath /tmp/spire-server/private/api.sock

# Check Keylime Verifier endpoint
curl -k https://localhost:8881/version || curl http://localhost:8881/version

# Check Keylime Registrar endpoint
curl http://localhost:8890/version

# Check service logs for errors
tail -20 /tmp/spire-server.log
tail -20 /tmp/keylime-verifier.log
tail -20 /tmp/keylime-registrar.log
```

**ON PREM API GATEWAY WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./test_onprem.sh --no-pause

# Verify processes are running
ps -aux | grep envoy
ps -aux | grep mobile-sensor-microservice
ps -aux | grep mtls-server

# Health checks (optional but recommended)
# Check Envoy is listening on port 8080
sudo ss -tlnp | grep :8080 || sudo netstat -tlnp | grep :8080

# Check Mobile Location Service endpoint
curl http://localhost:5000/verify -X POST -H "Content-Type: application/json" -d '{}'

# Check mTLS Server is listening on port 9443
sudo ss -tlnp | grep :9443 || sudo netstat -tlnp | grep :9443

# Check service logs for errors
tail -20 /opt/envoy/logs/envoy.log
tail -20 /tmp/mobile-sensor.log
tail -20 /tmp/mtls-server.log
```

**Quick Verification Summary:**

After running both setup scripts, verify all services are healthy:

**On Control Plane (10.1.0.11):**
```bash
# All services should show running processes
ps aux | grep -E "spire-server|keylime.cmd.verifier|keylime.cmd.registrar" | grep -v grep

# Quick health check one-liner
echo "SPIRE Server: $(./spire/bin/spire-server healthcheck -socketPath /tmp/spire-server/private/api.sock 2>&1 | head -1)"
echo "Keylime Verifier: $(curl -s -k https://localhost:8881/version 2>&1 | head -1 || echo 'not responding')"
echo "Keylime Registrar: $(curl -s http://localhost:8890/version 2>&1 | head -1 || echo 'not responding')"
```

**On On-Prem Gateway (10.1.0.10):**
```bash
# All services should show running processes
ps aux | grep -E "envoy|mobile-sensor|mtls-server" | grep -v grep

# Quick health check one-liner
echo "Envoy (port 8080): $(sudo ss -tlnp 2>/dev/null | grep :8080 >/dev/null && echo 'listening' || echo 'not listening')"
echo "Mobile Service (port 5000): $(curl -s -X POST http://localhost:5000/verify -H 'Content-Type: application/json' -d '{}' 2>&1 | head -1 || echo 'not responding')"
echo "mTLS Server (port 9443): $(sudo ss -tlnp 2>/dev/null | grep :9443 >/dev/null && echo 'listening' || echo 'not listening')"
```

**Common Issues:**
- If services don't start: Check logs in `/tmp/` (control plane) or `/opt/envoy/logs/` and `/tmp/` (on-prem)
- If ports are in use: Run cleanup scripts or manually stop conflicting services
- If health checks fail: Wait a few seconds for services to fully initialize, then retry

### Demo Act 2: The Happy Path (Proof of Geofencing)

*See Slides 7 and 19 for solution architecture and implementation details*

This act demonstrates the complete flow from workload attestation through successful geolocation verification.

#### Step 1: Start SPIRE Agent and Workload Services (e.g., 10.1.0.11)

**SOVEREIGN PUBLIC/EDGE CLOUD AGENT WINDOW:** (e.g., 10.1.0.11)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc
./test_agents.sh --no-pause
```

**What this script does:**
- Configures SPIRE Agent with TPM support
- Configures rust-keylime Agent with TPM support
- Creates SPIRE TPM Plugin server (sidecar)
- Registers agents with Keylime Registrar
- Creates SPIRE registration entries for workloads
- Tests the complete attestation flow
- Verifies workload SVID issuance with unified identity

**Expected output:**
- SPIRE Agent running with Workload API on Unix socket
- rust-keylime Agent running on port 9002
- TPM Plugin Server running and ready for certification requests

**Monitor logs (optional):**
```bash
# In separate terminals, watch logs:
tail -f /tmp/spire-agent.log            # SPIRE Agent
tail -f /tmp/rust-keylime-agent.log     # rust-keylime Agent
tail -f /tmp/tpm-plugin-server.log      # SPIRE TPM Plugin

# Or use the attestation watch script (filters for attestation events):
./watch-spire-agent-attestations.sh    # SPIRE Agent attestations only
```

**Verify setup:**
```bash
# Check SPIRE Agent health
spire-agent healthcheck

# Check SPIRE Server status
spire-server bundle show
```

#### Step 2: Start mTLS Client and Verify End-to-End Flow (e.g., 10.1.0.11)

**SOVEREIGN PUBLIC/EDGE CLOUD CLIENT APP WINDOW:** (e.g., 10.1.0.11)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc
./test_mtls_client.sh
```

**Note:** The client automatically saves the workload SVID certificate chain to `/tmp/svid-dump/svid.pem` for inspection.

**What happens:**

1. Client connects to SPIRE Agent Workload API
2. SPIRE Agent attests the client process and matches to registration entry
3. SPIRE Agent requests workload SVID from SPIRE Server
4. Workload SVID inherits unified identity claims from agent SVID (geolocation, TPM attestation)
5. Client uses workload SVID for mTLS connection to Envoy
6. Envoy verifies SPIRE certificate signature using SPIRE CA bundle
7. Envoy WASM filter extracts sensor ID and type from certificate chain
8. Envoy WASM filter behavior:
    - GPS/GNSS sensors: Trusted hardware, bypass mobile location service (allow directly)
    - Mobile sensors: Calls Mobile Location Service to verify geolocation
      - Prioritizes **DB-less flow** using coordinates/MSISDN extracted from SVID claims
      - Falls back to DB-BASED lookup if SVID data is incomplete
      - Mobile Location Service handles CAMARA API caching (15-min TTL, configurable)
10. Backend server logs the sensor ID for audit trail

**Expected output:**
```
╔════════════════════════════════════════════════════════════════╗
║  mTLS Client Starting with SPIRE SVID (Automatic Renewal)      ║
╚════════════════════════════════════════════════════════════════╝
SPIRE Agent socket: /tmp/spire-agent/public/api.sock
Server: e.g., 10.1.0.10:8080

  Mode: SPIRE (automatic SVID renewal enabled)
  ✓ Got initial SVID: spiffe://example.org/mtls-client
  ✓ Connected to server
  📤 Sending: HELLO #1
  📥 Received: SERVER ACK: HELLO #1
```

**Monitor client logs (optional):**
```bash
# Watch client output in the same terminal, or in a separate terminal:
tail -f /tmp/mtls-client-app.log
```

#### Step 3: Verify End-to-End Flow and Inspect Unified Identity Claims

**ON PREM API GATEWAY WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./watch-envoy-logs.sh
```

**Check Envoy logs for sensor verification:**
```bash
# On e.g., 10.1.0.10
sudo tail -f /opt/envoy/logs/envoy.log | grep -E '(sensor|verification|cache|TTL)'
```

**Expected log entries:**
- For mobile sensors:
  - `[LOCATION VERIFY] Initiating location verification...`
  - `[CACHE MISS]` or `[API CALL]` (first call)
  - `[CACHE HIT]` (subsequent calls within cache TTL)
  - `[LOCATION VERIFY] Location verification completed: result=true`
- For GPS/GNSS sensors:
  - `GPS/GNSS sensor: Trusted hardware, no mobile location service call needed - allowing request`
- `Sensor verification successful`

**ON PREM MOBILE LOCATION SERVICE WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./watch-mobile-sensor-logs.sh
```

**Check Mobile Location Service logs:**
```bash
# On e.g., 10.1.0.10
tail -f /tmp/mobile-sensor.log | grep -E '(CAMARA|authorize|token|verify_location|\[CACHE|\[LOCATION VERIFY|\[API)'
```

**Expected log entries:**
- `CAMARA verify_location caching: ENABLED (TTL: 900 seconds = 15.0 minutes)`
- `[LOCATION VERIFY] Initiating location verification...`
- `[CACHE MISS]` or `[API CALL]` (first call)
- `[CACHE HIT]` (subsequent calls within cache TTL)
- `[API RESPONSE] CAMARA verify_location API response... [CACHED for 900 seconds]`

**ON PREM SERVER APP WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./watch-mtls-server-logs.sh
```

**Check mTLS Server logs:**
```bash
# On e.g., 10.1.0.10
tail -f /tmp/mtls-server.log | grep -E '(Sensor ID|X-Sensor-ID)'
```

**Expected log entries:**
- `Client X HTTP GET /hello: HELLO #N [Sensor ID: 12d1:1433]`

**Check SPIRE Agent attestation:**
```bash
# On e.g., 10.1.0.11
./watch-spire-agent-attestations.sh
```

**Expected log entries showing:**
- Agent attestation with TPM App Key certification
- Unified identity SVID issuance with geolocation claims
- Workload SVID inheritance from agent SVID

**Inspect Unified Identity Claims:**
```bash
# On e.g., 10.1.0.11
# The SVID is automatically saved by test_mtls_client.sh to /tmp/svid-dump/svid.pem
# Inspect the SVID and claims
./scripts/dump-svid-attested-claims.sh /tmp/svid-dump/svid.pem
```

**Expected output shows:**
- Workload SPIFFE ID
- Agent SVID in certificate chain
- **AttestedClaims** including:
  - `grc.geolocation.*` (sensor_id, type, latitude, longitude)
  - `grc.tpm-attestation.*` (App Key cert, TPM quote data)
  - `grc.workload.*` (workload ID, key source)

### Demo Act 3: The Defense (The Rogue Admin)

*This demonstrates protection against insider threats as described in Slide 6*

This act demonstrates how the system detects and blocks insider threats when hardware integrity is compromised.

**SOVEREIGN PUBLIC/EDGE CLOUD AGENT WINDOW:** (e.g., 10.1.0.11)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc
./watch-spire-agent-attestations.sh
```
**SOVEREIGN PUBLIC/EDGE CLOUD CLIENT APP WINDOW:** (e.g., 10.1.0.11)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc
./test_mtls_client.sh
```
**SOVEREIGN PUBLIC/EDGE CLOUD ROGUE ADMIN WINDOW:** (e.g., 10.1.0.11)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc
./test_rogue_admin.sh

# Simulate rogue admin disconnecting the USB Mobile Sensor
sudo ./test_toggle_huawei_mobile_sensor.sh off

# Wait for system to detect the change and issue degraded SVID
# Then reconnect sensor to restore normal operation
sudo ./test_toggle_huawei_mobile_sensor.sh on
```

**What happens:**
1. Rogue admin disconnects USB Mobile Sensor (simulating physical tampering)
2. Keylime Agent detects the USB disconnect event via Dynamic Hardware Integrity monitoring
3. Hardware integrity score drops, triggering degraded attestation
4. SPIRE Agent attempts to refresh SVID but receives Degraded SVID (valid for network, missing Proof of Residency)
5. Client retries connection with degraded SVID
6. Envoy WASM Plugin verifies certificate and detects missing geolocation claim
8. System successfully blocks the request, proving protection against insider threats.

> [!IMPORTANT]
> **Degraded SVID Policy**: In a regulated enterprise, "Degraded SVIDs" are strictly policy-enforced. The Envoy API Gateway is configured to return a **403 Forbidden** for all PII-touching or sensitive "Green Zone" endpoints when a degraded SVID is presented, potentially triggering an immediate SOAR (Security Orchestration, Automation, and Response) alert.

**ON PREM API GATEWAY WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./watch-envoy-logs.sh
```
**ON PREM MOBILE LOCATION SERVICE WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./watch-mobile-sensor-logs.sh
```
**ON PREM SERVER APP WINDOW:** (e.g., 10.1.0.10)
```bash
cd ~/AegisSovereignAI/hybrid-cloud-poc/enterprise-private-cloud
./watch-mtls-server-logs.sh
```

**Expected log entries:**
- Envoy logs show: `403 Forbidden` with `Geo Claim Missing` error
- SPIRE Agent logs show: Degraded SVID issuance (missing geolocation claims)
- Keylime Agent logs show: USB sensor disconnect detection

### Troubleshooting

**Unified Identity - SVID missing geolocation claims:**
- Verify Keylime Verifier has verified the agent: `curl -k https://localhost:8881/v2.1/agents/`
- Check `unified_identity_enabled: true` is set in both `spire-server.conf` and `spire-agent.conf`.
- Ensure the Mobile Sensor Sidecar is reachable from the Keylime Verifier.

**Delegated Certification failing (Task 14b):**
- Verify the TPM Plugin Server is using HTTPS (mTLS) to talk to the rust-keylime agent.
- Check for "JSON format mismatch" in `/tmp/tpm-plugin-server.log`.
- Ensure `agent_uuid` in the attestation request matches the one registered in Keylime.

**mTLS Handshake Errors (Envoy/Client):**
- **Clock Drift**: Ensure all machines have synchronized time: `sudo ntpdate pool.ntp.org`.
- **Bundle Mismatch**: Verify Envoy has the latest SPIRE bundle: `openssl x509 -in /opt/envoy/certs/spire-bundle.pem -text -noout`.
- **WASM Fail-Closed**: If the WASM filter cannot reach the Mobile Sidecar, it will block connections with a 403. Check `/opt/envoy/logs/envoy.log` for upstream connection errors.

**SPIRE Agent not attesting:**
- Check TPM is accessible: `ls -la /dev/tpm*`
- Verify TPM Plugin Server is running: `ps aux | grep tpm-plugin`
- Check SPIRE Agent logs: `tail -f /tmp/spire-agent.log`

**Envoy not verifying certificates:**
- Verify SPIRE bundle exists: `ls -la /opt/envoy/certs/spire-bundle.pem`
- Check Envoy config: `sudo envoy --config-path /opt/envoy/envoy.yaml --mode validate`

**Mobile Location Service failing:**
- Check CAMARA core credentials in the mapping database (not environment variables in production).
- Verify sensor ID in database: `sqlite3 mobile-sensor-microservice/sensor_mapping.db "SELECT * FROM sensor_map;"`

**Client connection fails:**
- Verify Envoy certificate is copied: `ls -la ~/.mtls-demo/envoy-cert.pem`
- Check firewall rules: `sudo iptables -L -n | grep 8080`
- Verify SPIRE Agent socket: `ls -la /tmp/spire-agent/public/api.sock`

## Governance, Compliance & Standards

To meet the regulatory bar of an "End-to-End Zero Trust" architecture, AegisSovereignAI aligns each stage of the AI pipeline with industry standards and enterprise-grade requirements.

### Sovereign Trust Loop Mapping
| AI Pipeline Stage | AegisSovereignAI Component | Enterprise/Compliance Requirement | IETF Reference |
| --- | --- | --- | --- |
| **Ingress** | **ZKP Location/ID** | Privacy-Preserving KYC / Anti-Fraud | `draft-lkspa-wimse-verifiable-geo-fence` |
| **Processing** | **Confidential TEE** | Data-in-Use Protection | `draft-ietf-rats-architecture` |
| **Identity** | **DID + SVID (SPIFFE)**| Immutable Workload Identity | `draft-ni-a2a-ai-agent` |
| **Egress** | **SPIRE SVID / Open Policy Agent (OPA)** | Service-to-Service Auth / Data Loss Prevention (DLP) | `RFC 9535 (SPIFFE)` |

### IETF Draft Alignment Summary
| Stage | IETF Draft / Standard | Role in Enterprise Architecture |
| --- | --- | --- |
| **Ingress** | `draft-lkspa-wimse-verifiable-geo-fence` | Provides the **"Verifiable Geolocation"** framework for SPIFFE/SPIRE. |
| **Identity** | `draft-ni-a2a-ai-agent` | Establishes the **Agent Certificate Authority (ACA)** for AI workloads. |
| **Trust Bridge** | `draft-ietf-rats-architecture` | Defines the **Verifier** and **Relying Party** roles. |
| **Network** | `RFC 9535 (SPIFFE)` | Ensures **mTLS** between cloud and branch is identity-driven. |

### Silicon-to-Audit Trail

> [!IMPORTANT]
> **Silicon-to-Audit Compliance**: Regulators (e.g., **Office of the Comptroller of the Currency (OCC)**, Federal Reserve) require verifiable "receipts" for security architecture. AegisSovereignAI provides a continuous **Silicon-to-Audit** trail through:
- **Keylime Attestation Logs**: Cryptographic proof of host hardware and software integrity over time.
- **SPIRE SVID Issuance Logs**: Immutable records of every workload identity issued, bound to specific hardware measurements.
- **WASM Filter Logs**: Granular audit of every access request and the specific hardware-rooted claims that allowed or blocked it.

### Attestation Drift & Day 2 Operations
Maintaining a global hardware fleet requires managing **Attestation Drift**, where hardware updates (BIOS/Firmware/Kernel) change the "Known Good" state:
- **Continuous Lifecycle Management**: Integration with the **Keylime Verifier** allows for automated updates to the "Golden State" policy when patches are deployed, preventing false positives during maintenance windows.
- **Hardware Revocation**: If a physical TPM is retired or compromised, the corresponding **Endorsement Key (EK)** is blacklisted in the registrar. This immediately prevents any further SPIRE attestation for that hardware ID.
- **Dynamic Policy Enforcement**: BIOS-level tampering or unauthorized hardware swaps trigger an immediate measurement mismatch, revoking the agent's SVID and blocking all traffic in the Sovereign AI loop.

### Compromise Detection & Remediation (Unmanaged Devices)
For **unmanaged** retail or employee-owned (BYOD) devices, AegisSovereignAI moves from "Software Trustedness" to "Hardware-Rooted Attestation." Detecting a compromise on a device the bank does not control relies on three cryptographic feedback loops:

1.  **Hardware-Rooted State Verification (RATS/EAT)**: Even without MDM/Management, smartphones (iOS/Android) and laptops (TPM 2.0) can generate an **Entity Attestation Token (EAT)**. This token is signed by the **Secure Enclave** or **TPM**, proving that the device is not rooted or jailbroken, and that the banking app's code is untampered.
2.  **App-Level Integrity Proofs**: The framework uses **ZKP-based circuits** to verify that the AI engagement app is running in a secure, non-debuggable memory space. If an attacker attempts to attach a debugger or intercept the AI prompt, the hardware-rooted "Environment Claim" fails, and the attestation quote is rejected by the Sovereign Cloud.
3.  **Deterministic SVID Revocation**: Once the **Keylime Verifier** or **Ingress Gateway** detects an integrity mismatch (e.g., a "Golden State" deviation), the device's SVID is immediately and automatically flagged for revocation.
    *   **Remediation**: The Envoy API Gateway, seeing a revoked or "Hardware-Fail" SVID, returns a **403 Forbidden** for all sensitive PII endpoints. This ensures that a compromised device is cryptographically and instantaneously quarantined from the Sovereign AI Loop, regardless of its management status.

> [!NOTE]
> **Jailbreak/Root Resilience**: While an OS *can* be jailbroken, hardware-rooted attestation makes that compromise **mathematically visible**. Because the hardware Secure Enclave measures the kernel during boot, a jailbroken OS cannot produce a valid "integrity quote" that matches the bank's requirements.

### Security & Trust Model Assumptions (IETF RATS Alignment)
To provide "Silicon-to-Audit" guarantees, AegisSovereignAI aligns with the **IETF RATS (Remote Attestation Procedures)** architecture:

1.  **The Trust Anchor (Attester Root)**: We assume the **Device Silicon (TPM/Secure Enclave)** and the **Immutable Boot ROM** are uncompromised. This hardware root of trust is the only component that can sign **Evidence** (Quotes/Claims).
2.  **Verified Integrity (Static Appraisal)**: Any compromise that persists across reboots (e.g., a modified kernel) is caught during the **Evidence Appraisal** stage. The verifier compares the boot-time hardware quote against the **Reference Integrity Manifest (RIM)**—the "Answer Key" signed by the OEM.
3.  **Runtime Protection (Dynamic Appraisal)**: For volatile "runtime jailbreaks" that occur after boot, the framework uses **Linux IMA (Integrity Measurement Architecture)**. The system continuously measures every binary, script, and kernel module as they are loaded. If an unauthorized rooting tool or exploit payload is executed, the **Evidence** sent to the verifier will deviate from the **Appraisal Policy**, revoking the SVID within seconds.
4.  **Mathematical Enforcement**: The system moves the security boundary from *Managerial Trust* (MDM) to *Mathematical Trust* (Remote Attestation). A jailbroken device is not "blocked" from existing; it is simply mathematically incapable of producing the cryptographic proof required to access the bank's Sovereign AI Loop.

#### Scaling: Hardware Key Management & OEM Trust
A common question for Tier-1 institutions is: *"Do we have to manually track every OS update and hash for every customer device?"*

The answer is **No.** AegisSovereignAI utilizes **Reference Integrity Manifests (RIM)**:

1.  **OEM Reference Manifests (RIM)**: This is the **"Answer Key"** provided by the manufacturer (Apple, Google, Microsoft). It contains the *expected* hashes of every official OS and firmware component.
2.  **The TPM Quote**: This is the **"Actual Snapshot"** produced by the customer's hardware. It reflects the *current* state of the device silicon and kernel.
3.  **Automated Comparison**: The bank's **Keylime Verifier** ingests the **signed RIM (Answer Key)** and compares it to the **received Quote (Snapshot)**. 
4.  **Zero-Touch Verification**: The bank doesn't "guess" what a good build looks like; it simply verifies that the device **proves** it matches the **OEM-signed global manifest.**
5.  **Scaling**: This allows the bank to support billions of unmanaged devices without ever having to manually manage an OS hash. The bank trusts the **OEM's Signature** on the manifest, and the **Hardware's Signature** on the quote.

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
- **Mobile Location Service**: CAMARA API integration
- **Open Source**: [Envoy Proxy](https://www.envoyproxy.io/)
## Documentation

- **[End-to-End Sovereign Unified Identity & Trust Framework](README-arch-sovereign-unified-identity.md)**: The core technical spec for Stage 1 (Ingress) and the Unified Identity pipeline.
- [Enterprise Private Cloud README](enterprise-private-cloud/README.md) - Detailed setup and architecture
- [Python App Demo README](python-app-demo/README.md) - Client/server usage
- [test_agents.sh](test_agents.sh) - Agent services integration test script
- [test_control_plane.sh](test_control_plane.sh) - Control plane services test script
- [test_integration.sh](test_integration.sh) - Complete integration test script

## Logs

### Log File Locations

**On 10.1.0.11 (Sovereign Cloud):**
- SPIRE Server: `/tmp/spire-server.log`
- SPIRE Agent: `/tmp/spire-agent.log`
- Keylime Verifier: `/tmp/keylime-verifier.log`
- rust-keylime Agent: `/tmp/rust-keylime-agent.log`
- TPM Plugin Server: `/tmp/tpm-plugin-server.log`

**On e.g., 10.1.0.10 (On-Prem):**
- Envoy: `/opt/envoy/logs/envoy.log` (requires sudo)
- mTLS Server: `/tmp/mtls-server.log`
- Mobile Location Service: `/tmp/mobile-sensor.log`

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

## Demo Script: 3-Act Presentation

For a guided demonstration following the slide deck structure, use the 3-Act demo script:

```bash
./demo-3-act-presentation.sh
```

This script guides the audience through the presentation slides:

### **Introduction: The Sovereign Challenge**
*Refer to Slides 1-6*

- **Slide 1-5**: Introduction and context
- **Slide 6**: The Problem - A Fragile and Non-Verifiable Security Model
  - Explains the problem: fragile IP-based geofencing and insider threats
  - Introduces the Unified Identity solution

### **Act 1: The Setup (Trusted Infrastructure)**
*Refer to Slide 12: Implementation Architecture*

- Shows the architecture (Sovereign Cloud ↔ On-Prem Private Cloud)
- Demonstrates Keylime Verifier establishing hardware root of trust with TPM
- Verifies all services are running
- **Slide 12** displays the complete end-to-end solution architecture

### **Act 2: The Happy Path (Proof of Geofencing)**
*Refer to Slides 7 and 19*

- **Slide 7**: The Solution - Zero-Trust, HW-Rooted, Unified Identity
- Shows SPIRE Agent fetching Unified SVID with:
  - Workload Attestation (Software identity)
  - Host Attestation (TPM proof)
  - Geolocation Proof (From Keylime Agent Plugin)
- Decodes and displays the SVID certificate structure
- Demonstrates successful client connection with 200 OK from Envoy
- Shows WASM Plugin verification of Proof of Geofencing (PoG)
- **Slide 19** shows the implementation flow

### **Act 3: The Defense (The Rogue Admin)**
*Refer to Slide 6: Problem - Insider Threats*

- Simulates rogue admin disconnecting USB Mobile Sensor
- Shows Keylime Agent detecting the USB disconnect event
- Demonstrates Degraded SVID issuance (valid for network, missing PoR)
- Shows client reconnection attempt
- **Key demonstration**: Envoy WASM Plugin returns **403 Forbidden** with error **"Geo Claim Missing"**
- Proves the system blocks requests when geolocation proof is missing
- Addresses the insider threat scenario from **Slide 6**

### **Conclusion: Value Delivered**
*Refer to Slides 13-18*

- Summarizes the move from Phase I (replayable credentials) to Phase II (HW-anchored proofs)
- Highlights three key achievements:
  1. Strong Residency Guarantees (auditable)
  2. Protection against Insider Threats
  3. Unified Identity bound to physical hardware

**Prerequisites for Demo:**
- All services running on both machines (see Quick Start Guide above)
- USB Mobile Sensor connected (for Act 2)
- Root/sudo access for sensor toggle script

**Note:** The demo script automatically handles sensor disconnection/reconnection for Act 3.
