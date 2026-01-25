# 30-60-90 Day Roadmap: Unified Ingress Pilot (CCB)

This roadmap outlines the phased pilot of the **Unified Ingress** model at the Customer Center of Banking (CCB), focusing on the **Private Wealth Gen-AI Advisory** use case.

## Phase 1: Foundation (Days 1-30)
**Goal:** Establish the technical foundation and hardware-rooted identity baseline.

- [ ] **Infrastructure Setup**: Deploy Aegis Control Plane (SPIRE + Aegis Verifier) in the CCB staging environment.
- [ ] **Device Onboarding**: Enroll 50 pilot mobile devices (Apple Silicon Macs and strongBox-enabled Androids) into the Keylime Registrar.
- [ ] **SVID Schema Finalization**: Formalize the `grc.geolocation` and `grc.tpm-attestation` OIDs in the enterprise certificate policy.
- [ ] **Baseline Attestation**: Verify continuous TPM-based attestation for all pilot devices with 99.9% reliability.

## Phase 2: Privacy-Preserving Compliance (Days 31-60)
**Goal:** Integrate ZKP-based geolocation and verify regulatory compliance.

- [ ] **Plonky2 Integration**: Deploy the Rust-based Geofence Sidecar to pilot devices.
- [ ] **Geofence Policy Audit**: Define and cryptographically sign the "US-Authorized" and "EEA-Compliance" boundary polygons.
- [ ] **ZKP Verification at Ingress**: Enable the Envoy WASM filter to verify Plonky2 proofs in real-time for all AI Advisory API calls.
- [ ] **Mock Audit Run**: Perform a data-less audit with the internal compliance team to prove Reg-K compliance without fetching raw GPS data.

## Phase 3: Scaling & Optimization (Days 61-90)
**Goal:** Optimize performance and prepare for production rollout.

- [ ] **Performance Tuning**: Amortize ZKP proof generation costs (target < 50ms) and optimize SVID caching at the gateway.
- [ ] **Revocation Workflows**: Implement and test automated SVID revocation triggered by hardware integrity failures (e.g., detected jailbreak).
- [ ] **Enterprise Integration**: Connect Aegis metrics to the CCB Prometheus/Grafana dashboard for real-time visibility.
- [ ] **Pilot Report & Gating**: Present results to the CCB Risk Committee for production launch approval.

---
> [!NOTE]
> This pilot assumes that the **Silicon Root of Trust** is active on all participating devices. Device models without TPM 2.0 or Secure Enclave are excluded from the initial pilot phase.
