#!/usr/bin/env python3

# Copyright 2025 AegisSovereignAI Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Unified-Identity - Verification: SPIRE API & Policy Staging (Stubbed Keylime)
Python script to fetch Sovereign SVID with AttestedClaims from SPIRE Agent Workload API using gRPC directly.

This script uses gRPC to call the Workload API directly, allowing access to AttestedClaims
from the protobuf response.

Requirements:
    pip install grpcio protobuf
"""
import os
import sys
import json
import subprocess
from pathlib import Path

try:

    
    import grpc
    from google.protobuf import json_format
except ImportError:
    print("Error: grpcio and protobuf libraries not installed")
    print("Install them with: pip install grpcio protobuf")
    sys.exit(1)

# Add the go-spiffe proto directory to path to import generated protobufs
# Note: We'll need to generate Python stubs from the .proto file
# For now, we'll use a workaround by calling the protobuf compiler or using reflection

def generate_proto_stubs():
    """Generate Python stubs from workload.proto if not already generated."""
    proto_dir = Path(__file__).parent.parent / "go-spiffe" / "proto" / "spiffe" / "workload"
    proto_file = proto_dir / "workload.proto"
    output_dir = Path(__file__).parent / "generated"

    if not proto_file.exists():
        print(f"Error: Proto file not found at {proto_file}")
        return False

    # Check if already generated
    generated_file = output_dir / "spiffe" / "workload" / "workload_pb2.py"
    if generated_file.exists():
        return True

    try:
        import subprocess
        output_dir.mkdir(parents=True, exist_ok=True)

        # Generate Python stubs using protoc
        result = subprocess.run(
            [
                "protoc",
                f"--proto_path={proto_dir.parent.parent.parent}",
                f"--python_out={output_dir}",
                str(proto_file)
            ],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print(f"✓ Generated Python protobuf stubs in {output_dir}")
            return True
        else:
            print(f"Warning: Failed to generate protobuf stubs: {result.stderr}")
            print("You may need to install protoc: https://grpc.io/docs/protoc-installation/")
            return False
    except FileNotFoundError:
        print("Warning: protoc not found. Cannot generate protobuf stubs.")
        print("Install protoc: https://grpc.io/docs/protoc-installation/")
        return False

def wait_for_agent_svid_in_logs(agent_log_path="/tmp/spire-agent.log", max_wait_seconds=60, check_interval=2):
    """
    Wait for SPIRE agent to have an SVID in the logs before proceeding.

    Args:
        agent_log_path: Path to SPIRE agent log file
        max_wait_seconds: Maximum time to wait in seconds (default: 60)
        check_interval: Interval between log checks in seconds (default: 2)

    Returns:
        bool: True if SVID found in logs, False if timeout
    """
    import time

    if not os.path.exists(agent_log_path):
        print(f"  ⚠ Agent log file not found at {agent_log_path}")
        print("  Will proceed anyway - agent may be logging elsewhere")
        return True  # Proceed anyway

    print("  Waiting for SPIRE agent to have SVID in logs...")
    print(f"  Checking log file: {agent_log_path}")

    start_time = time.time()
    check_count = 0

    # Patterns that indicate agent has SVID ready
    svid_patterns = [
        "Node attestation was successful",
        "SVID loaded",
        "spiffe://",
    ]

    while time.time() - start_time < max_wait_seconds:
        try:
            with open(agent_log_path, 'r') as f:
                log_content = f.read()

            # Check if any SVID pattern is found
            for pattern in svid_patterns:
                if pattern in log_content:
                    elapsed = int(time.time() - start_time)
                    print(f"  ✓ Found SVID indicator in agent logs after {elapsed}s")
                    # Wait a bit more to allow registration entries to propagate
                    # Agent syncs with server every ~5 seconds, so wait longer to ensure entry propagation
                    print("  Waiting additional 15s for registration entries to propagate...")
                    time.sleep(15)
                    return True
        except Exception as e:
            # If we can't read the log, continue waiting
            pass

        check_count += 1
        if check_count % 5 == 0:  # Show progress every 5 checks
            elapsed = int(time.time() - start_time)
            print(f"  ... still waiting for SVID in logs ({elapsed}s/{max_wait_seconds}s)...")

        time.sleep(check_interval)

    elapsed = int(time.time() - start_time)
    print(f"  ⚠ Timeout waiting for SVID in agent logs after {elapsed}s")
    print("  Will proceed anyway - agent may have SVID but not logged it yet")
    return False  # Timeout, but we'll still try

def fetch_from_workload_api_grpc(max_wait_seconds=60):
    """
    Unified-Identity - Verification: Fetch SVID from SPIRE Agent Workload API using gRPC directly.

    This function uses gRPC to call the Workload API, allowing access to AttestedClaims
    from the protobuf response. It waits for the agent to have an SVID in logs before calling.

    Args:
        max_wait_seconds: Maximum time to wait for agent SVID in logs (default: 60)

    Returns:
        tuple: (cert_pem, attested_claims_json) or (None, None) on error
    """
    socket_path = "/tmp/spire-agent/public/api.sock"

    if not os.path.exists(socket_path):
        print(f"Error: SPIRE Agent socket not found at {socket_path}")
        print("Make sure SPIRE Agent is running")
        return None, None

    print("Connecting to SPIRE Agent Workload API via gRPC...")
    print("  Socket: /tmp/spire-agent/public/api.sock")
    print("  (This Python process will be attested by the agent)")
    print()

    try:
        # Try to import generated protobufs
        generated_dir = Path(__file__).parent / "generated"
        if generated_dir.exists():
            sys.path.insert(0, str(generated_dir))

        try:
            from spiffe.workload import workload_pb2
            from spiffe.workload import workload_pb2_grpc
        except ImportError:
            # If protobufs not generated, try to generate them
            if generate_proto_stubs():
                from spiffe.workload import workload_pb2
                from spiffe.workload import workload_pb2_grpc
            else:
                print("Error: Cannot import workload protobufs")
                print("Please generate them manually:")
                print(f"  protoc --proto_path=../go-spiffe/proto --python_out=generated ../go-spiffe/proto/spiffe/workload/workload.proto")
                print(f"  python -m grpc_tools.protoc --proto_path=../go-spiffe/proto --python_out=generated --grpc_python_out=generated ../go-spiffe/proto/spiffe/workload/workload.proto")
                return None, None

        # Create gRPC channel to Unix socket
        # gRPC uses 'unix:' prefix for Unix domain sockets (absolute path required)
        abs_socket_path = os.path.abspath(socket_path)
        channel = grpc.insecure_channel(f'unix:{abs_socket_path}')

        # Wait for channel to be ready (with timeout)
        try:
            grpc.channel_ready_future(channel).result(timeout=5)
        except Exception as e:
            print(f"  ⚠ Warning: Channel not ready after 5s: {e}")
            print("  Will proceed anyway - channel may become ready during call")

        # Create stub
        stub = workload_pb2_grpc.SpiffeWorkloadAPIStub(channel)

        # Create request (empty for FetchX509SVID)
        request = workload_pb2.X509SVIDRequest()

        # Unified-Identity - Verification: Add required security header for Workload API
        # The SPIRE Agent requires the "workload.spiffe.io" metadata header
        # This is a security measure to ensure the client is aware it's calling the Workload API
        # For streaming RPCs in Python gRPC, metadata is passed as a list of (key, value) tuples
        grpc_metadata = [('workload.spiffe.io', 'true')]

        # Wait for agent to have SVID in logs before calling gRPC
        # This ensures the agent is ready before we make the call
        wait_for_agent_svid_in_logs(max_wait_seconds=min(max_wait_seconds, 30))

        # Verify current process UID matches registration entry selector
        import pwd
        current_uid = os.getuid()
        print(f"  Current process UID: {current_uid}")
        print(f"  Registration entry should have selector: unix:uid:{current_uid}")

        # Verify registration entry exists on server
        print("  Verifying registration entry exists on SPIRE server...")
        import subprocess
        script_dir = Path(__file__).parent
        spire_server_bin = script_dir.parent / "spire" / "bin" / "spire-server"
        
        entry_exists = False
        if spire_server_bin.exists():
            try:
                result = subprocess.run(
                    [str(spire_server_bin), "entry", "show", 
                     "-spiffeID", "spiffe://example.org/python-app",
                     "-socketPath", "/tmp/spire-server/private/api.sock"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                if result.returncode == 0 and "spiffe://example.org/python-app" in result.stdout:
                    entry_exists = True
                    print(f"  ✓ Registration entry exists on server")
                    # Check if selector matches
                    if f"unix:uid:{current_uid}" in result.stdout:
                        print(f"  ✓ Selector matches current UID ({current_uid})")
                    else:
                        print(f"  ⚠ Warning: Selector in entry may not match current UID")
                        print(f"  Entry details:")
                        for line in result.stdout.split('\n')[:10]:
                            if line.strip():
                                print(f"    {line}")
                else:
                    print(f"  ⚠ Registration entry not found on server")
                    if result.stderr:
                        print(f"  Server error: {result.stderr[:200]}")
            except Exception as e:
                print(f"  ⚠ Could not verify entry on server: {e}")

        # Wait briefly for registration entry to propagate to agent, then proceed with gRPC call
        # SPIRE agent syncs with server periodically (typically every 5-10 seconds)
        # The streaming RPC will handle waiting for the SVID if the entry is available
        import time
        if entry_exists:
            # Entry exists on server - wait briefly for agent sync, then proceed
            # Streaming RPC will wait for SVID if entry is available
            print("  Waiting briefly for agent to sync entry (agent syncs every 5-10s)...")
            time.sleep(10)  # Give agent one sync cycle
            print("  Proceeding with gRPC call (streaming will wait for SVID if needed)")
        else:
            # Entry doesn't exist on server - wait longer to give it time to be created
            print("  ⚠ Registration entry not found on server")
            print("  Waiting up to 30s for entry to be created and synced...")
            entry_wait_start = time.time()
            max_entry_wait = 30
            while time.time() - entry_wait_start < max_entry_wait:
                # Re-check if entry exists on server
                try:
                    result = subprocess.run(
                        [str(spire_server_bin), "entry", "show", 
                         "-spiffeID", "spiffe://example.org/python-app",
                         "-socketPath", "/tmp/spire-server/private/api.sock"],
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    if result.returncode == 0 and "spiffe://example.org/python-app" in result.stdout:
                        entry_exists = True
                        elapsed = int(time.time() - entry_wait_start)
                        print(f"  ✓ Registration entry found on server after {elapsed}s")
                        print("  Proceeding with gRPC call (streaming will wait for SVID)")
                        break
                except Exception:
                    pass
                
                elapsed = int(time.time() - entry_wait_start)
                if elapsed > 0 and elapsed % 10 == 0:
                    print(f"  ... still waiting for entry creation ({elapsed}s/{max_entry_wait}s)...")
                
                time.sleep(2)
            
            if not entry_exists:
                print("  ⚠ Registration entry not found on server after waiting")
                print("  Proceeding anyway - gRPC call will fail if entry doesn't exist")

        print()
        print("Calling FetchX509SVID...")
        # Streaming RPC will handle waiting for SVID if entry is available

        import time
        import signal

        # The agent needs time to:
        # 1. Attest this process (extract UID, etc.)
        # 2. Match selectors to registration entry
        # 3. Fetch SVID from server if not cached
        # For streaming RPCs, the agent will send updates when SVID becomes available

        # Set a timeout for the entire gRPC call (60 seconds total)
        grpc_timeout_seconds = 60
        start_time = time.time()

        try:
            # For streaming RPCs, we can't set timeout directly, so we'll check elapsed time in the loop
            responses = stub.FetchX509SVID(request, metadata=grpc_metadata)

            # Get the first response (streaming may send multiple updates)
            # The agent will send updates when SVID becomes available
            response = None
            max_wait_updates = 30  # Reduced from 40 - wait for up to 30 updates
            update_count = 0
            last_update_time = time.time()

            for resp in responses:
                # Check if we've exceeded the overall timeout
                elapsed = time.time() - start_time
                if elapsed >= grpc_timeout_seconds:
                    print(f"  ⚠ Timeout after {elapsed:.1f}s waiting for SVID")
                    print("  This usually means:")
                    print("    1. Registration entry hasn't propagated to agent yet")
                    print("    2. Process selectors don't match the entry")
                    print("    3. Agent hasn't fetched SVID from server yet")
                    print("    4. Agent is not responding to Workload API requests")
                    print("  Try:")
                    print("    - Check agent logs: tail -20 /tmp/spire-agent.log")
                    print("    - Verify entry: ../spire/bin/spire-server entry show -spiffeID spiffe://example.org/python-app")
                    print("    - Check agent is running: ps aux | grep spire-agent")
                    return None, None

                update_count += 1
                last_update_time = time.time()
                
                if resp.svids and len(resp.svids) > 0:
                    response = resp
                    print(f"  ✓ SVID received after {update_count} update(s) ({elapsed:.1f}s)")
                    break

                # If we've waited too long, give up
                if update_count >= max_wait_updates:
                    print(f"  ⚠ No SVID after {max_wait_updates} updates ({elapsed:.1f}s)")
                    print("  This usually means:")
                    print("    1. Registration entry hasn't propagated to agent yet")
                    print("    2. Process selectors don't match the entry")
                    print("    3. Agent hasn't fetched SVID from server yet")
                    print("  Try:")
                    print("    - Check agent logs: tail -20 /tmp/spire-agent.log")
                    print("    - Verify entry: ../spire/bin/spire-server entry show -spiffeID spiffe://example.org/python-app")
                    return None, None

                # Show progress for long waits
                if update_count % 5 == 0:
                    elapsed = time.time() - start_time
                    print(f"  ... still waiting (update {update_count}/{max_wait_updates}, {elapsed:.1f}s elapsed)...")

            if not response:
                elapsed = time.time() - start_time
                print(f"  ⚠ No SVID received from agent after {elapsed:.1f}s")
                print("  Check agent logs for details: tail -20 /tmp/spire-agent.log")
                return None, None

        except grpc.RpcError as e:
            # If we get a permission denied error, log it and return
            if e.code() == grpc.StatusCode.PERMISSION_DENIED:
                error_msg = str(e.details()) if e.details() else str(e)
                if "no identity issued" in error_msg.lower():
                    elapsed = time.time() - start_time if 'start_time' in locals() else 0
                    print(f"  ⚠ Got 'no identity issued' error after {elapsed:.1f}s")
                    print("  This means the agent doesn't have an SVID for this workload yet.")
                    print("  Possible causes:")
                    print(f"    1. Registration entry hasn't propagated to agent (agent syncs every 5-10s)")
                    print(f"    2. Process UID ({current_uid}) doesn't match entry selector")
                    print(f"    3. Entry doesn't exist on server")
                    print("  Troubleshooting:")
                    print("    - Check agent logs: tail -30 /tmp/spire-agent.log | grep -E '(python-app|Entry|attest)'")
                    print("    - Verify entry: ../spire/bin/spire-server entry show -spiffeID spiffe://example.org/python-app -socketPath /tmp/spire-server/private/api.sock")
                    print(f"    - Check current UID: id -u (should match entry selector unix:uid:{current_uid})")
                    print("    - Wait a few seconds and try again (agent syncs periodically)")
                    return None, None
            elif e.code() == grpc.StatusCode.DEADLINE_EXCEEDED:
                elapsed = time.time() - start_time if 'start_time' in locals() else 0
                print(f"  ⚠ gRPC call timed out after {elapsed:.1f}s")
                print("  The agent may not be responding or the registration entry hasn't propagated")
                print("  Check agent logs: tail -20 /tmp/spire-agent.log")
                return None, None
            # Re-raise other errors
            raise
        except Exception as e:
            elapsed = time.time() - start_time if 'start_time' in locals() else 0
            print(f"  ⚠ Error during gRPC call after {elapsed:.1f}s: {e}")
            print("  Check agent logs: tail -20 /tmp/spire-agent.log")
            return None, None

        if not response.svids:
            print("Error: No SVIDs in response")
            return None, None

        # Get the first SVID
        svid = response.svids[0]

        # Unified-Identity - Verification: Check bundle for agent SVID
        # The bundle field contains the trust domain bundle (root CA)
        # We'll also check if agent SVID might be available elsewhere

        # Extract certificate chain (SPIRE automatically includes full chain in x509_svid)
        from cryptography import x509
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.backends import default_backend

        cert_der = svid.x509_svid
        bundle_der = svid.bundle if hasattr(svid, 'bundle') and svid.bundle else None

        # Unified-Identity - Verification: SPIRE automatically returns the full certificate chain
        # The x509_svid field contains DER-encoded certificate chain:
        #   - Workload SVID (leaf certificate)
        #   - Agent SVID (intermediate certificate that signed the workload)
        # SPIRE agent/server code automatically includes the agent SVID in the chain

        try:
            # SPIRE automatically includes the full certificate chain in x509_svid
            # According to workload.proto: "ASN.1 DER encoded certificate chain. MAY include
            # intermediates, the leaf certificate (or SVID itself) MUST come first."
            # The DER bytes contain concatenated certificates: workload + agent (if included)
            cert_der_bytes = bytes(cert_der)
            certs = []
            offset = 0
            max_iterations = 10  # Safety limit

            # Parse all certificates from concatenated DER bytes
            # SPIRE sends certificates as concatenated DER, so we iterate until we've parsed all
            # We need to parse the DER structure to find the exact length of each certificate
            iteration = 0
            while offset < len(cert_der_bytes) and iteration < max_iterations:
                iteration += 1

                # Check if we have enough bytes for a certificate header
                if offset + 4 > len(cert_der_bytes):
                    break

                # DER certificates start with SEQUENCE tag (0x30)
                if cert_der_bytes[offset] != 0x30:
                    if certs:
                        # We've parsed at least one cert, so we're likely done
                        break
                    else:
                        raise ValueError(f"Invalid DER certificate start at offset {offset}: expected 0x30, got 0x{cert_der_bytes[offset]:02x}")

                # Parse DER length field to get the exact certificate length
                # Length can be short form (1 byte) or long form (2+ bytes)
                length_offset = offset + 1
                if length_offset >= len(cert_der_bytes):
                    break

                first_length_byte = cert_der_bytes[length_offset]

                if first_length_byte & 0x80 == 0:
                    # Short form: length is in the single byte
                    cert_content_length = first_length_byte
                    cert_total_length = 1 + 1 + cert_content_length  # tag + length + content
                else:
                    # Long form: first byte indicates number of length bytes
                    length_bytes_count = first_length_byte & 0x7F
                    if length_bytes_count == 0 or length_bytes_count > 4:
                        # Invalid length encoding
                        if certs:
                            break
                        else:
                            raise ValueError(f"Invalid DER length encoding at offset {length_offset}")

                    if length_offset + 1 + length_bytes_count > len(cert_der_bytes):
                        break

                    # Read the length bytes (big-endian)
                    cert_content_length = 0
                    for i in range(length_bytes_count):
                        cert_content_length = (cert_content_length << 8) | cert_der_bytes[length_offset + 1 + i]

                    cert_total_length = 1 + 1 + length_bytes_count + cert_content_length  # tag + length_byte + length_bytes + content

                # Extract the certificate bytes
                cert_end = offset + cert_total_length
                if cert_end > len(cert_der_bytes):
                    # Not enough bytes for this certificate
                    if certs:
                        break
                    else:
                        raise ValueError(f"Incomplete certificate at offset {offset}: need {cert_total_length} bytes, have {len(cert_der_bytes) - offset}")

                cert_bytes = cert_der_bytes[offset:cert_end]

                # Parse the certificate
                try:
                    cert = x509.load_der_x509_certificate(cert_bytes, default_backend())
                    certs.append(cert)
                except Exception as parse_error:
                    if certs:
                        # We've parsed at least one cert, so if parsing fails, we're likely done
                        break
                    else:
                        raise parse_error

                # Move to next certificate
                offset = cert_end

                # If we've consumed all bytes, we're done
                if offset >= len(cert_der_bytes):
                    break

            if not certs:
                raise ValueError("No certificates found in DER bytes")

            # Convert all certificates to PEM and concatenate
            cert_pem_chain = ""
            for cert in certs:
                cert_pem = cert.public_bytes(encoding=serialization.Encoding.PEM).decode('utf-8')
                cert_pem_chain += cert_pem

            cert_count = len(certs)
            cert = certs[0]  # Use first cert (workload) for claims extraction

            # Unified-Identity - Verification: If only workload certificate found, fetch agent SVID
            # According to architecture, the chain should be: Workload SVID + Agent SVID
            # SPIRE's Workload API may not include agent SVID in x509_svid field
            # So we need to fetch it separately and append it to complete the chain
            if cert_count == 1:
                # Check if there are more bytes after the first certificate
                first_cert_der = certs[0].public_bytes(encoding=serialization.Encoding.DER)
                if len(cert_der_bytes) > len(first_cert_der):
                    print(f"  ⚠ Debug: DER bytes length ({len(cert_der_bytes)}) > first cert length ({len(first_cert_der)})")
                    print(f"  ⚠ Debug: There may be additional certificates, but parsing failed")
                    print(f"  ⚠ Debug: Remaining bytes: {len(cert_der_bytes) - len(first_cert_der)}")

                # Unified-Identity - Verification: Get agent SVID to complete the chain per architecture
                # According to architecture doc, the chain should include: Workload SVID + Agent SVID
                workload_cert = certs[0]
                workload_issuer = workload_cert.issuer

                print(f"  Fetching agent SVID to complete certificate chain (per architecture)...")
                print(f"  Workload SVID issuer: {workload_issuer.rfc4514_string()}")

                agent_svid_found = False

                # Method 1: Try to get agent SVID from SPIRE server via agent list and SVID mint
                try:
                    script_dir = Path(__file__).parent
                    spire_server_bin = script_dir.parent / "spire" / "bin" / "spire-server"

                    if not spire_server_bin.exists():
                        for path in [Path("/opt/spire/bin/spire-server"), Path("/usr/local/bin/spire-server")]:
                            if path.exists():
                                spire_server_bin = path
                                break

                    if spire_server_bin.exists():
                        # List agents to get agent SPIFFE ID
                        list_result = subprocess.run(
                            [str(spire_server_bin), "agent", "list", "-socketPath", "/tmp/spire-server/private/api.sock", "-output", "json"],
                            capture_output=True,
                            text=True,
                            timeout=10
                        )

                        if list_result.returncode == 0:
                            import json as json_lib
                            try:
                                agents_data = json_lib.loads(list_result.stdout)
                                if agents_data and 'agents' in agents_data and len(agents_data['agents']) > 0:
                                    # Get agent SPIFFE ID
                                    agent_spiffe_id = None
                                    for agent in agents_data['agents']:
                                        if 'id' in agent:
                                            if isinstance(agent['id'], dict):
                                                td = agent['id'].get('trust_domain', '')
                                                path = agent['id'].get('path', '')
                                                if td and path:
                                                    agent_spiffe_id = f"spiffe://{td}{path}"
                                            elif isinstance(agent['id'], str) and '/spire/agent/' in agent['id']:
                                                agent_spiffe_id = agent['id']

                                        if agent_spiffe_id and '/spire/agent/' in agent_spiffe_id:
                                            print(f"  Found agent SPIFFE ID: {agent_spiffe_id}")

                                            # Try to mint/get agent SVID from server
                                            # Note: This may require server API access which workloads don't have
                                            # For now, we document that SPIRE should include it automatically
                                            print(f"  ⚠ Note: Cannot access agent SVID via server API (requires server credentials)")
                                            print(f"  SPIRE server/agent code should automatically include agent SVID in chain")
                                            break
                            except Exception as e:
                                pass
                except Exception:
                    pass

                # Since we can't get agent SVID via available APIs, document the limitation
                if not agent_svid_found:
                    print(f"  ⚠ Agent SVID not available via Workload API or Server API (workload access)")
                    print(f"  According to architecture, SPIRE should include agent SVID in x509_svid chain")
                    print(f"  This may require SPIRE server/agent code modifications to include it automatically")

        except Exception as e:
            # Fallback: try parsing as single certificate (for compatibility)
            try:
                cert = x509.load_der_x509_certificate(cert_der, default_backend())
                cert_pem_chain = cert.public_bytes(encoding=serialization.Encoding.PEM).decode('utf-8')
                cert_count = 1
                print(f"  ⚠ Warning: Could not parse certificate chain, got single certificate: {e}")
                print(f"  SPIRE should automatically include agent SVID in the chain")
            except Exception as e2:
                raise Exception(f"Failed to parse certificate(s) from DER bytes: {e2}")

        print(f"✓ SVID fetched successfully")
        print(f"  SPIFFE ID: {svid.spiffe_id}")
        print(f"  Certificate chain: {cert_count} certificate(s)")
        if cert_count >= 2:
            print(f"  ✓ Full chain received: Workload SVID + Agent SVID (as expected)")
        elif cert_count == 1:
            print(f"  ⚠ Warning: Only workload certificate in chain")
            print(f"  SPIRE should automatically include agent SVID in the chain")
        print()

        # Unified-Identity - Verification: Extract Unified Identity claims from certificate extension
        # Try new Unified Identity extension (OID 1.3.6.1.4.1.99999.2) first, then legacy (1.3.6.1.4.1.99999.1)
        claims_json = None
        extension_claims = None
        try:
            # Try new Unified Identity extension (Verification)
            oid = x509.ObjectIdentifier("1.3.6.1.4.1.99999.2")
            ext = cert.extensions.get_extension_for_oid(oid)
            ext_value = ext.value.value if hasattr(ext.value, "value") else ext.value
            extension_claims = json.loads(ext_value)
        except Exception:
            try:
                # Fall back to legacy AttestedClaims extension (if present)
                oid = x509.ObjectIdentifier("1.3.6.1.4.1.99999.1")
                ext = cert.extensions.get_extension_for_oid(oid)
                ext_value = ext.value.value if hasattr(ext.value, "value") else ext.value
                extension_claims = json.loads(ext_value)
            except Exception:
                extension_claims = None

        # Unified-Identity - Verification: Prioritize Unified Identity extension claims
        if extension_claims is not None:
            # Verification: Use Unified Identity claims from certificate extension
            claims_json = extension_claims
        elif response.attested_claims:
            # Fall back to protobuf AttestedClaims (if Unified Identity extension not present)
            # Convert protobuf AttestedClaims to JSON
            claims_list = []
            for claim in response.attested_claims:
                claim_dict = {
                    "geolocation": claim.geolocation,
                    "host_integrity_status": claim.HostIntegrity.Name(claim.host_integrity_status),
                }

                if claim.gpu_metrics_health:
                    claim_dict["gpu_metrics_health"] = {
                        "status": claim.gpu_metrics_health.status,
                        "utilization_pct": claim.gpu_metrics_health.utilization_pct,
                        "memory_mb": claim.gpu_metrics_health.memory_mb,
                    }

                claims_list.append(claim_dict)

            # For simplicity, use the first claim (or combine them)
            if len(claims_list) == 1:
                claims_json = claims_list[0]
            else:
                claims_json = {"claims": claims_list} if claims_list else None
        else:
            claims_json = None

        channel.close()
        return cert_pem_chain, claims_json

    except Exception as e:
        print(f"Error fetching SVID via gRPC: {e}")
        import traceback
        traceback.print_exc()
        print()
        print("Troubleshooting:")
        print("  1. Ensure SPIRE Agent is running:")
        print("     ps aux | grep spire-agent")
        print("  2. Check agent socket exists:")
        print("     ls -la /tmp/spire-agent/public/api.sock")
        print("  3. Verify registration entry:")
        print("     ../spire/bin/spire-server entry show -spiffeID spiffe://example.org/python-app -socketPath /tmp/spire-server/private/api.sock")
        print("  4. Check agent logs:")
        print("     tail -20 /tmp/spire-agent.log")
        print("  5. If protobuf import fails, generate stubs:")
        print("     python -m grpc_tools.protoc --proto_path=../go-spiffe/proto --python_out=generated --grpc_python_out=generated ../go-spiffe/proto/spiffe/workload/workload.proto")
        return None, None

def main():
    print("=" * 70)
    print("Unified-Identity - Verification: Fetching Sovereign SVID (gRPC)")
    print("=" * 70)
    print()
    print("Note: Using gRPC directly to access AttestedClaims from Workload API")
    print("      Architecture: Python App → SPIRE Agent (gRPC) → SPIRE Server")
    print()

    output_dir = Path("/tmp/svid-dump")
    output_dir.mkdir(exist_ok=True)

    # Fetch SVID from Workload API using gRPC
    print("Fetching SVID from SPIRE Agent Workload API via gRPC...")
    cert_pem, claims_json = fetch_from_workload_api_grpc()

    if cert_pem:
        cert_file = output_dir / "svid.pem"
        # Write the full certificate chain (workload + agent if available)
        cert_file.write_text(cert_pem)

        # Save AttestedClaims if available (for reference, but claims are in certificate extension)
        if claims_json:
            claims_file = output_dir / "attested_claims.json"
            claims_file.write_text(json.dumps(claims_json, indent=2))
            print(f"✓ SVID certificate saved to: {cert_file}")
            print(f"✓ AttestedClaims saved to: {claims_file}")
        else:
            print(f"✓ SVID certificate saved to: {cert_file}")
            print("(Note: AttestedClaims not available in response)")
    else:
        print("Error: Could not fetch SVID")
        sys.exit(1)

if __name__ == "__main__":
    main()
