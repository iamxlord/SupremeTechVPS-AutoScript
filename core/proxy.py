#!/usr/bin/env python3
import socket, threading, select, os, sys

# ======================================================================
# SUPREME-TECH UNIVERSAL ADAPTIVE PROXY
# Multi-Port, Smart Protocol Evasion, Zero-Data Ready
# Ports: 80 (Standard), 8080 (Alt-HTTP), 2082 (cPanel), 8443 (Squid SSL)
# ======================================================================

LISTENING_PORTS = [80, 8080, 2082]
SSH_PORT = 109 
RESP_FILE = '/etc/xray/proxy_resp.txt'

def handle_client(client_socket):
    server_socket = None
    try:
        # ==========================================
        # 1. ADAPTIVE NETWORK OPTIMIZATIONS (1MB BUFFERS)
        # ==========================================
        # Increase Receive and Send buffers to 1MB to absorb DPI sweeps
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)
        
        # Disable Nagle's Algorithm (Forces instant packet delivery)
        try: client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        
        # Aggressive Keep-Alives (Defeat DPI Idle Timeouts)
        try: client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        except: pass
        try: client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, 30) # Ping after 30s silence
        except: pass
        try: client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, 10) # Retry every 10s
        except: pass
        try: client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPCNT, 5)   # Drop after 5 fails
        except: pass
        
        request_data = client_socket.recv(1048576)
        if not request_data: return
            
        # ==========================================
        # 2. BACKEND CONNECTION (Dropbear/SSH)
        # ==========================================
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try: server_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        try: server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        except: pass
        
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        # ==========================================
        # 3. SMART PROTOCOL DETECTION (DPI BYPASS)
        # ==========================================
        if request_data.startswith(b'SSH-2.0'):
            # PURE TCP MODE: Client sent SSH handshake. Forward silently.
            server_socket.sendall(request_data)
        else:
            # WEBSOCKET MODE: Parse HTTP and send 101 Switching Protocols
            request_str = request_data.decode('utf-8', errors='ignore')
            http_protocol = "HTTP/1.1" 
            if request_str:
                first_line = request_str.split('\r\n')[0]
                parts = first_line.split(' ')
                if len(parts) >= 3 and parts[2].startswith("HTTP/"):
                    http_protocol = parts[2].strip()
            
            custom_resp = "Switching Protocols"
            if os.path.exists(RESP_FILE):
                try:
                    with open(RESP_FILE, 'r') as f:
                        content = f.read().strip()
                        if content: custom_resp = content
                except: pass
                
            response = f"{http_protocol} 101 {custom_resp}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            client_socket.sendall(response.encode('utf-8'))
                
            # TCP Pipelining Catch (Extracts early SSH handshakes hidden in HTTP buffers)
            if b'\r\n\r\n' in request_data:
                leftover = request_data.split(b'\r\n\r\n', 1)[1]
                if leftover: server_socket.sendall(leftover)
            elif b'\n\n' in request_data:
                leftover = request_data.split(b'\n\n', 1)[1]
                if leftover: server_socket.sendall(leftover)
                
        # ==========================================
        # 4. FULL-DUPLEX ADAPTIVE BUFFERING LOOP
        # ==========================================
        while True:
            # 300-second idle timeout kills zombie connections, saving VPS RAM
            r, w, x = select.select([client_socket, server_socket], [], [], 300)
            if not r: break 
            
            if client_socket in r:
                data = client_socket.recv(1048576)
                if not data: break
                server_socket.sendall(data)
                
            if server_socket in r:
                data = server_socket.recv(1048576)
                if not data: break
                client_socket.sendall(data)
                
    except Exception as e:
        # Silently pass broken pipes to prevent thread crashing under heavy load
        pass
    finally:
        # Mathematically perfect garbage collection
        try: client_socket.close()
        except: pass
        if server_socket: 
            try: server_socket.close()
            except: pass

def start_server(port):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('0.0.0.0', port))
        # Massive backlog allowance to handle connection spikes
        server.listen(500)
        print(f"[*] Supreme-Tech Proxy listening on port {port}")
        while True:
            client_sock, addr = server.accept()
            threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
    except Exception as e:
        print(f"[-] Failed to bind port {port}: {e}")

if __name__ == "__main__":
    print("[*] Starting Supreme-Tech Universal SSH-WS & Raw TCP Proxy...")
    # Start all secondary ports in background daemon threads
    for port in LISTENING_PORTS[:-1]:
        threading.Thread(target=start_server, args=(port,), daemon=True).start()
    # Start the primary port in the main thread to keep the service running
    start_server(LISTENING_PORTS[-1])
