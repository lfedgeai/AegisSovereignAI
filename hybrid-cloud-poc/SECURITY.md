# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in AegisSovereignAI, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, please email: **security@lfedge.org**

Include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide an initial assessment within 7 business days.

## Supported Versions

| Version | Supported |
|---------|-----------|
| main branch | ✅ Active development |
| Tagged releases | ✅ Security patches |

## Security Architecture

This project implements a defense-in-depth security model:

- **Hardware Root of Trust**: TPM 2.0 Endorsement Keys (EK) and Attestation Keys (AK) anchor all identity claims to silicon.
- **Attestation**: Keylime continuously verifies host integrity via TPM quotes and IMA measurement lists.
- **Privacy-Preserving Proofs**: Zero-Knowledge Proofs (Plonky2) prove geolocation claims without revealing exact coordinates.
- **Mutual TLS**: All inter-service communication uses SPIRE-issued SVIDs with X.509 certificates.
- **TOCTOU Protection**: PCR 15 extension binds geolocation measurements to the TPM quote, preventing time-of-check/time-of-use attacks.

## Scope

The following are **in scope** for security reports:
- Bypass of TPM attestation or quote verification
- ZKP proof forgery or verification bypass
- SVID issuance without proper attestation
- Credential leakage in logs or error messages
- Geolocation spoofing that bypasses hardware verification

The following are **out of scope**:
- Vulnerabilities in upstream dependencies (report to the respective project)
- Denial of service on demo/test endpoints
- Issues requiring physical access to the TPM hardware

## Disclosure Policy

We follow coordinated disclosure. Once a fix is available, we will:
1. Release a patched version
2. Publish a security advisory on GitHub
3. Credit the reporter (unless anonymity is requested)
