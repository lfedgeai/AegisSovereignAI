
import ssl
import socket
import sys

def try_connect(name, context_opts):
    try:
        print(f"--- Trying {name} ---")
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_REQUIRED
        context.load_verify_locations(cafile="/opt/envoy/certs/envoy-cert.pem")
        context.load_cert_chain(
            certfile="/tmp/svid-dump/svid.pem",
            keyfile="/tmp/svid-dump/svid-key.pem"
        )
        
        if 'min_version' in context_opts:
            context.minimum_version = context_opts['min_version']
        if 'max_version' in context_opts:
            context.maximum_version = context_opts['max_version']
        if 'ciphers' in context_opts:
            context.set_ciphers(context_opts['ciphers'])
            
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect(("10.1.0.11", 8080))
        
        ssock = context.wrap_socket(sock, server_hostname="localhost")
        ssock.do_handshake()
        print("  SUCCESS!")
        print(f"  Version: {ssock.version()}")
        print(f"  Cipher: {ssock.cipher()}")
        ssock.close()
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False

# Test 1: Default
try_connect("Default", {})

# Test 2: TLS 1.2 Only
try_connect("TLS 1.2", {'min_version': ssl.TLSVersion.TLSv1_2, 'max_version': ssl.TLSVersion.TLSv1_2})

# Test 3: TLS 1.3 Only
try_connect("TLS 1.3", {'min_version': ssl.TLSVersion.TLSv1_3, 'max_version': ssl.TLSVersion.TLSv1_3})

# Test 4: Default + AES256-GCM-SHA384 (match openssl)
# Note: In TLS 1.3 ciphers suites are different but we can try setting commonly used
try_connect("Limited Ciphers", {'ciphers': 'AES256-GCM-SHA384'})
