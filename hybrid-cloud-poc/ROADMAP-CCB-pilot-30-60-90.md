# Strategic Pilot Roadmap: AegisSovereignAI for CCB
## High-Net-Worth (HNW) AI Advisory Use Case

This roadmap outlines the 90-day execution plan to transition the AegisSovereignAI framework from PoC to a production-ready pilot for the JPMC **Consumer & Community Banking (CCB)** division.

---

### **Phase 1: Foundation & Managed Core (Days 1–30)**
**Goal:** Establish the hardware-rooted control plane for JPMC-managed infrastructure and employee hardware.

*   **Workstream 1 (Infrastructure):** Deploy the SPIRE/Keylime control plane across three sovereign on-prem zones.
*   **Workstream 2 (Managed Edge):** Enroll Tier-1 (Managed) LOB laptops for HNW wealth advisors. Enable continuous IMA attestation for data-rich advisory applications.
*   **Workstream 3 (Audit Loop):** Integrate the "Silicon-to-Audit" trail with the JPMC Internal Risk Dashboard.
*   **Milestone:** First "Sovereign-Attested" AI advisory session on a managed LOB device.

---

### **Phase 2: Verified Ingress & BYOD Pilot (Days 31–60)**
**Goal:** Extend the trust boundary to unmanaged HNW customer devices via Verified Ingress.

*   **Workstream 4 (Mobile SDK):** Integrate the Aegis Ingress SDK (App Attest/Key Attestation) into the JPM Private Banking mobile app.
*   **Workstream 5 (ZKP Geofencing):** Implement ZKP-verified geofencing for Reg-K compliance in high-risk regions.
*   **Workstream 6 (Aegis Verifier):** Instantiate the Aegis Verifier as the "Trust Bridge" between OEM Root CAs and the bank's SPIRE server.
*   **Milestone:** A HNW customer performs a trade verification from a personal iPhone with **Point-in-Time** hardware attestation.

---

### **Phase 3: Mature Sovereignty & LOB Isolation (Days 61–90)**
**Goal:** Achieve full architectural saturation and demonstrate multi-tenancy at the glass.

*   **Workstream 7 (Enterprise Egress):** Deploy Stage 2 (Trusted Egress) to ensure AI inference never touches unvetted data center infrastructure.
*   **Workstream 8 (LOB Isolation):** Enforce SVID-based isolation between "Public AI" and "HNW Advisory AI" at the Envoy Gateway.
*   **Workstream 9 (ARB Handover):** Conduct final technical and strategic review with the Architecture Review Board (ARB) for global rollout.
*   **Milestone:** Full end-to-end auditability from "Customer Glass to Sovereign Core" in a live pilot environment.

---

### **Success Metrics (The "Board Ready" KPI)**
1.  **Zero-Trust Coverage:** 100% of HNW AI requests must carry a hardware-rooted SVID.
2.  **Compliance Velocity:** Reduce audit response time for Reg-K from "weeks" to "real-time" via SVID claims.
3.  **Threat Resilience:** 0% success for spoofed location attempts in adversarial testing.
