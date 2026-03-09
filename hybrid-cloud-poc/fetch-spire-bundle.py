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
Fetch SPIRE Trust Bundle (CA Certificate)
Extracts the SPIRE CA certificate bundle for use with standard cert servers.

Uses direct gRPC calls to SPIRE Agent Workload API (no python-spiffe dependency).
"""

import os
import sys
import subprocess
import importlib.util
import time
import random
from pathlib import Path

# Simple SPIFFE ID class
class SimpleSpiffeId:
    """Simple SPIFFE ID parser."""
    def __init__(self, spiffe_id_str):
        self._str = spiffe_id_str
        if not spiffe_id_str.startswith('spiffe://'):
            raise ValueError(f"Invalid SPIFFE ID: {spiffe_id_str}")
        parts = spiffe_id_str[9:].split('/', 1)
        self.trust_domain = parts[0]
        self.path = '/' + parts[1] if len(parts) > 1 else '/'
    
    def __str__(self):
        return self._str

try:
    import grpc
    HAS_GRPC = True
except ImportError:
    print("Error: grpcio library not installed")
    print("Install it with: pip install grpcio")
    sys.exit(1)

try:
    from cryptography import x509
    from cryptography.hazmat.primitives import serialization
except ImportError:
    print("Error: cryptography library not installed")
    print("Install it with: pip install cryptography")
    sys.exit(1)


import argparse
import json
import base64

# OID for Unified Identity Claims
UNIFIED_IDENTITY_OID = "1.3.6.1.4.1.65284.1.1"

def fetch_bundle_via_grpc(socket_path):
    """Fetch trust bundle and leaf SVID from SPIRE Agent via direct gRPC."""
    script_dir = Path(__file__).parent / "python-app-demo"
    workload_pb2_path = script_dir / "generated" / "spiffe" / "workload" / "workload_pb2.py"
    workload_pb2_grpc_path = script_dir / "generated" / "spiffe" / "workload" / "workload_pb2_grpc.py"

    if not workload_pb2_path.exists() or not workload_pb2_grpc_path.exists():
        # Try to generate protobuf stubs
        proto_dir = Path(__file__).parent / "go-spiffe" / "proto" / "spiffe" / "workload"
        proto_file = proto_dir / "workload.proto"
        output_dir = script_dir / "generated"
        if proto_file.exists():
            output_dir.mkdir(parents=True, exist_ok=True)
            proto_path = str(proto_dir.parent.parent)
            generated = False
            # Try grpc_tools.protoc first (generates stubs compatible with installed protobuf library)
            try:
                from grpc_tools import protoc as grpc_protoc
                ret = grpc_protoc.main([
                    'grpc_tools.protoc', f'--proto_path={proto_path}',
                    f'--python_out={output_dir}', f'--grpc_python_out={output_dir}',
                    str(proto_file)
                ])
                if ret == 0:
                    generated = True
            except Exception:
                pass
            # Fall back to system protoc
            if not generated:
                try:
                    result = subprocess.run(
                        ["protoc", f"--proto_path={proto_path}", f"--python_out={output_dir}", str(proto_file)],
                        capture_output=True, text=True
                    )
                    if result.returncode == 0:
                        generated = True
                except FileNotFoundError:
                    pass
            if not generated or not workload_pb2_path.exists():
                raise ImportError(f"Protobuf files not found and could not be generated: {workload_pb2_path}")
        else:
            raise ImportError(f"Protobuf files not found: {workload_pb2_path}")

    # Ensure __init__.py files exist for package imports
    gen_dir = script_dir / "generated"
    for sub in ["spiffe", "spiffe/workload"]:
        init_file = gen_dir / sub / "__init__.py"
        if not init_file.exists():
            init_file.parent.mkdir(parents=True, exist_ok=True)
            init_file.touch()
    # Load protobuf modules
    import types
    import sys
    
    if 'spiffe' not in sys.modules or hasattr(sys.modules.get('spiffe'), '__path__'):
        spiffe_module = types.ModuleType('spiffe')
        spiffe_module.__path__ = []
        sys.modules['spiffe'] = spiffe_module
    
    if 'spiffe.workload' not in sys.modules:
        spiffe_workload = types.ModuleType('spiffe.workload')
        spiffe_workload.__path__ = []
        sys.modules['spiffe.workload'] = spiffe_workload

    spec_pb2 = importlib.util.spec_from_file_location("workload_pb2", workload_pb2_path)
    workload_pb2 = importlib.util.module_from_spec(spec_pb2)
    spec_pb2.loader.exec_module(workload_pb2)
    sys.modules['spiffe.workload.workload_pb2'] = workload_pb2
    
    spec_grpc = importlib.util.spec_from_file_location("workload_pb2_grpc", workload_pb2_grpc_path)
    workload_pb2_grpc = importlib.util.module_from_spec(spec_grpc)
    spec_grpc.loader.exec_module(workload_pb2_grpc)

    max_attempts = 5
    attempt = 0
    backoff = 1.0
    abs_socket_path = socket_path.replace('unix://', '')
    response = None

    while attempt < max_attempts:
        attempt += 1
        try:
            if not os.path.exists(abs_socket_path) and attempt < max_attempts:
                raise Exception(f"Socket not found at {abs_socket_path}")

            channel = grpc.insecure_channel(f'unix:{abs_socket_path}')
            stub = workload_pb2_grpc.SpiffeWorkloadAPIStub(channel)
            grpc_metadata = [('workload.spiffe.io', 'true')]

            request = workload_pb2.X509SVIDRequest()
            rpc_timeout = 5 if attempt < max_attempts else 15
            response_stream = stub.FetchX509SVID(request, metadata=grpc_metadata, timeout=rpc_timeout)
            response = next(response_stream)

            if not response or not response.svids:
                raise Exception("No SVIDs in response")
            break
        except (grpc.RpcError, Exception) as e:
            if attempt < max_attempts:
                wait_time = backoff + random.uniform(0, 0.5)
                time.sleep(wait_time)
                backoff *= 2
            else:
                raise e

    svid_response = response.svids[0]
    spiffe_id_str = getattr(svid_response, 'spiffe_id', "")
    spiffe_id = SimpleSpiffeId(spiffe_id_str)

    # Extract leaf DER cert
    leaf_cert_der = svid_response.x509_svid
    # If it's a chain (concatenated DER), load_der_certs will handle it
    
    def load_der_certs(data):
        if not data: return []
        certs = []
        pos = 0
        while pos < len(data):
            if data[pos] != 0x30: break
            start = pos
            try:
                pos += 1
                if pos >= len(data): break
                length = data[pos]
                pos += 1
                if length & 0x80:
                    n = length & 0x7f
                    if pos + n > len(data): break
                    length = int.from_bytes(data[pos:pos+n], 'big')
                    pos += n
                full_len = pos - start + length
                cert_data = data[start:start+full_len]
                cert = x509.load_der_x509_certificate(cert_data)
                certs.append(cert)
                pos = start + full_len
            except Exception:
                break
        return certs

    svid_certs = load_der_certs(leaf_cert_der)
    
    bundle_certs = []
    bundle_der = getattr(svid_response, 'bundle', None)
    if bundle_der:
        bundle_certs = load_der_certs(bundle_der)
        
    channel.close()
    svid_key_der = getattr(svid_response, 'x509_svid_key', b'')
    return spiffe_id, bundle_certs, svid_certs, svid_key_der

def dump_claims(svid_certs, svid_key_der=b''):
    """Extract and dump Unified Identity claims from SVID."""
    if not svid_certs:
        return
    
    # Unified Identity can be in leaf or agent SVID (intermediate)
    claims = {}
    print(f"  Checking {len(svid_certs)} certificate(s) in SVID chain...")
    for i, cert in enumerate(svid_certs):
        spiffe_id = "unknown"
        try:
            for ext in cert.extensions:
                if ext.oid._name == 'subjectAltName':
                    for name in ext.value:
                        if hasattr(name, 'value') and isinstance(name.value, str) and name.value.startswith('spiffe://'):
                            spiffe_id = name.value
                            break
        except: pass
        
        print(f"  - Cert [{i}]: SPIFFE ID: {spiffe_id}")
        
        for ext in cert.extensions:
            if ext.oid.dotted_string == UNIFIED_IDENTITY_OID:
                print(f"    ✓ Found Unified Identity extension in cert [{i}]")
                # Value is usually an octet string containing UTF-8 JSON
                try:
                    # Cryptography returns the raw extension value (DER octet string)
                    # We need to unwrap the octet string if it's there, or just take bytes
                    val = ext.value.value
                    if isinstance(val, bytes):
                        # Some versions of cryptography/SPIRE might wrap this
                        # Try to parse as JSON directly
                        try:
                            claims = json.loads(val.decode('utf-8'))
                        except:
                            # Try to strip leading/trailing non-JSON if any
                            s = val.decode('utf-8', errors='ignore')
                            start = s.find('{')
                            end = s.rfind('}')
                            if start != -1 and end != -1:
                                claims = json.loads(s[start:end+1])
                    break
                except Exception as e:
                    print(f"  ⚠ Failed to parse claims from extension: {e}")
        if claims:
            break
            
    if claims:
        dump_path = Path("/tmp/svid-dump/attested_claims.json")
        dump_path.parent.mkdir(parents=True, exist_ok=True)
        with open(dump_path, 'w') as f:
            json.dump(claims, f, indent=2)
        print(f"✓ Dumped SVID claims to {dump_path}")
    else:
        print("⚠ No Unified Identity claims found in SVID chain")

    # Also export each SVID cert as PEM for downstream tools (e.g. verify-zkp-svid.py)
    dump_dir = Path("/tmp/svid-dump")
    dump_dir.mkdir(parents=True, exist_ok=True)
    for i, cert in enumerate(svid_certs):
        pem_path = dump_dir / f"svid.{i}.pem"
        with open(pem_path, 'wb') as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))
    if svid_certs:
        print(f"✓ Dumped {len(svid_certs)} SVID cert(s) as PEM to {dump_dir}/svid.*.pem")

    # Export the SVID private key if available
    if svid_key_der:
        from cryptography.hazmat.primitives import serialization as key_serial
        try:
            from cryptography.hazmat.primitives.serialization import load_der_private_key
            privkey = load_der_private_key(svid_key_der, password=None)
            key_pem = privkey.private_bytes(
                encoding=key_serial.Encoding.PEM,
                format=key_serial.PrivateFormat.PKCS8,
                encryption_algorithm=key_serial.NoEncryption()
            )
            key_path = dump_dir / "svid.0.key"
            with open(key_path, 'wb') as f:
                f.write(key_pem)
            os.chmod(str(key_path), 0o600)
            print(f"✓ Dumped SVID private key to {key_path}")
        except Exception as e:
            print(f"⚠ Failed to export SVID private key: {e}")

def main():
    parser = argparse.ArgumentParser(description='Fetch SPIRE Trust Bundle or Dump SVID Claims')
    parser.add_argument('--dump-only', action='store_true', help='Dump SVID claims instead of fetching bundle')
    parser.add_argument('--socket', default=os.environ.get('SPIRE_AGENT_SOCKET', '/tmp/spire-agent/public/api.sock'), help='SPIRE Agent socket path')
    parser.add_argument('--output', default=os.environ.get('BUNDLE_OUTPUT_PATH', '/tmp/spire-bundle.pem'), help='Output path for bundle')
    args = parser.parse_args()

    raw_socket = args.socket
    if "://" in raw_socket:
        socket_path = raw_socket
    else:
        socket_path = f"unix://{raw_socket}"

    try:
        spiffe_id, bundle_certs, svid_certs, svid_key_der = fetch_bundle_via_grpc(socket_path)

        if args.dump_only:
            dump_claims(svid_certs, svid_key_der)
            return

        print(f"Trust domain: {spiffe_id.trust_domain}")
        print(f"SPIFFE ID: {spiffe_id}")

        if not bundle_certs:
            print("Error: Trust bundle has no X509 authorities")
            sys.exit(1)

        # Write bundle to file
        bundle_pem = b""
        for cert in bundle_certs:
            bundle_pem += cert.public_bytes(serialization.Encoding.PEM)

        output_dir = os.path.dirname(args.output)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir, mode=0o755, exist_ok=True)

        with open(args.output, 'wb') as f:
            f.write(bundle_pem)

        print(f"✓ Successfully extracted SPIRE trust bundle to {args.output}")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
