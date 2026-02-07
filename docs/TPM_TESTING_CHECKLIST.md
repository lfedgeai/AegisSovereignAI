# TPM Hardware Testing Checklist

**MUST complete this BEFORE submitting any PRs to SPIRE upstream.**

## Prerequisites

- Linux machine with TPM 2.0 hardware
- SSH access to test machine
- Clean checkout of the overlay branch

## Phase 1: Build Verification

```bash
# SSH to TPM-enabled Linux machine
ssh user@<TPM_HOST>
cd <PROJECT_ROOT>

# Fetch and checkout the branch
git fetch origin
git checkout <BRANCH_NAME>

# Build SPIRE with overlay
./scripts/spire-build.sh

# Verify binaries
ls -lh build/spire-binaries/
file build/spire-binaries/spire-server
file build/spire-binaries/spire-agent

# Expected output:
# spire-server: ~114MB, ELF 64-bit LSB executable
# spire-agent:  ~44MB, ELF 64-bit LSB executable
```

**✅ Pass criteria:** Binaries build successfully, correct size/type

## Phase 2: TPM Detection

```bash
# Verify TPM 2.0 is available
ls /dev/tpm*
# Expected: /dev/tpm0 or /dev/tpmrm0

# Check TPM capabilities
tpm2_getcap properties-fixed
tpm2_getcap handles-persistent

# Test TPM access
tpm2_getrandom 8 --hex
# Expected: 8-byte random hex value
```

**✅ Pass criteria:** TPM 2.0 detected and accessible

## Phase 3: Integrated Testing (Recommended)

Run the complete integration test suite:

```bash
cd hybrid-cloud-poc

# Run full integration tests
# Replace <HOST> with your test machine IP/hostname
./test_integration.sh \
  --control-plane-host <HOST> \
  --agents-host <HOST> \
  --onprem-host <HOST>

# This will:
# 1. Build SPIRE with overlay
# 2. Start SPIRE server
# 3. Start SPIRE agents with TPM attestation
# 4. Run Keylime verification
# 5. Test sovereign attestation flow
# 6. Verify SVID generation with claims
# 7. Run enterprise on-prem tests
```

**✅ Pass criteria:** All tests pass, no errors in output

## Phase 4: Manual Testing (Optional - For Debugging)

If integrated tests fail, debug with individual components:

### 4a. SPIRE Server

```bash
cd hybrid-cloud-poc

# Start server
./test_control_plane.sh

# Verify server is running
ps aux | grep spire-server
netstat -tuln | grep 8081

# Check server logs
tail -f /tmp/spire-server.log
```

### 4b. TPM Agent Attestation

```bash
# Start agent with TPM
./test_agents.sh

# Verify agent logs
tail -f /tmp/spire-agent.log
# Look for: "TPM DevID attestation successful"

# Check agent registration
../build/spire-binaries/spire-server agent list
```

### 4c. Keylime Integration

```bash
# Check keylime status
curl -X GET http://localhost:8080/attestation/status

# Monitor keylime verifier
journalctl -u keylime_verifier -f
```

### 4d. SVID Verification

```bash
# Fetch workload SVID
../build/spire-binaries/spire-agent api fetch x509

# Verify sovereign attestation extension in output
```

**✅ Pass criteria:** Each component works individually

## Phase 5: Stress Testing

```bash
# Run multiple attestation cycles
cd hybrid-cloud-poc
for i in {1..10}; do
    echo "=== Iteration $i ==="
    ./test_integration.sh \
      --control-plane-host <HOST> \
      --agents-host <HOST> \
      --onprem-host <HOST>
    sleep 5
done

# Check system stability
ps aux | grep spire  # Processes should be running
dmesg | tail -50      # No critical errors
free -h               # Memory usage stable
```

**✅ Pass criteria:** System stable over 10 iterations, no memory leaks

## Phase 6: Evidence Collection

Collect all evidence for PR documentation:

```bash
# Create evidence package
mkdir -p <PROJECT_ROOT>/tpm-test-evidence

# Copy logs
cp /tmp/spire-server.log <PROJECT_ROOT>/tpm-test-evidence/
cp /tmp/spire-agent.log <PROJECT_ROOT>/tpm-test-evidence/
journalctl -u keylime_verifier > <PROJECT_ROOT>/tpm-test-evidence/keylime.log

# TPM info
tpm2_getcap properties-fixed > <PROJECT_ROOT>/tpm-test-evidence/tpm-info.txt

# System info
uname -a > <PROJECT_ROOT>/tpm-test-evidence/system-info.txt
cat /proc/cpuinfo | grep "model name" | head -1 >> <PROJECT_ROOT>/tpm-test-evidence/system-info.txt

# Package versions
dpkg -l | grep tpm2 > <PROJECT_ROOT>/tpm-test-evidence/tpm-packages.txt

# Create tarball
cd <PROJECT_ROOT>
tar czf tpm-test-evidence.tar.gz tpm-test-evidence/
```

**✅ Pass criteria:** All logs collected, no errors

## Phase 7: Test Report

Create test report:

```markdown
# TPM Testing Report

**Date:** <TEST_DATE>
**System:** Linux <TPM_HOST>, Kernel <KERNEL_VERSION>
**TPM:** TPM 2.0, <TPM_MANUFACTURER>
**SPIRE:** v1.10.3 + Aegis overlay

## Test Results

- ✅ Build: Success
- ✅ TPM Detection: Success
- ✅ Server Startup: Success
- ✅ Agent Attestation: Success
- ✅ Sovereign Attestation: Success
- ✅ Keylime Integration: Success
- ✅ SVID Generation: Success
- ✅ Stress Test: Success (10 iterations)

## Attestation Flow Verified

1. Agent detects TPM 2.0 chip
2. Generates DevID from TPM
3. Server verifies TPM attestation
4. Keylime performs remote attestation
5. Sovereign claims added to SVID
6. Geolocation data included

## Evidence

See attached: tpm-test-evidence.tar.gz

## Issues Found

[None / List any issues]

## Conclusion

The SPIRE overlay system successfully performs hardware attestation
on real TPM 2.0 hardware. Ready for upstream submission.
```

---

## Final Checklist

Before submitting PRs:

- [ ] All 7 phases passed
- [ ] Evidence collected and archived
- [ ] Test report written
- [ ] No errors in any logs
- [ ] Attestation flow works end-to-end
- [ ] Stress test passed (10 iterations)
- [ ] Performance acceptable
- [ ] Ready to demonstrate to SPIRE maintainers

**Only proceed to PR submission after ALL boxes checked!**

---

## Troubleshooting

### TPM Not Detected
```bash
# Check TPM device
ls -l /dev/tpm*
# Should show: /dev/tpm0, /dev/tpmrm0

# Check kernel module
lsmod | grep tpm
# Should show: tpm_tis, tpm_crb, etc.

# Load TPM module if missing
sudo modprobe tpm_tis
sudo modprobe tpm_crb
```

### Build Failures
```bash
# Clean build
cd <PROJECT_ROOT>
rm -rf build/
./scripts/spire-build.sh

# Check Go version
go version  # Should be 1.21+

# Install dependencies
cd spire-overlay
go mod download
```

### Attestation Failures
```bash
# Check SPIRE agent logs
tail -f /tmp/spire-agent.log | grep -i "tpm\|error"

# Verify TPM attestation plugin loaded
spire-agent api fetch x509 -socketPath /tmp/spire-agent/public/api.sock

# Check TPM ownership
tpm2_getcap properties-fixed | grep -i "owned"
```

### Keylime Integration Issues
```bash
# Restart Keylime services
sudo systemctl restart keylime_verifier
sudo systemctl restart keylime_registrar

# Check Keylime status
sudo systemctl status keylime_verifier
sudo journalctl -u keylime_verifier -n 100

# Verify Keylime config
cat /etc/keylime.conf | grep -i "tpm"
```

### Performance Issues
```bash
# Check TPM performance
time tpm2_getcap properties-fixed
# Should complete in < 1 second

# Monitor system resources
top -p $(pgrep spire)
# CPU < 50%, Memory stable

# Check for errors
dmesg | grep -i "tpm\|error"
journalctl -xe | grep -i "spire"
```
