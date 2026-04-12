import socket, threading, select, os

LISTENING_PORTS = [80, 8080]
SSH_PORT = 109 
RESP_FILE = '/etc/xray/proxy_resp.txt'

def handle_client(client_socket):
    server_socket = None
    try:
        # ==========================================
        # 1. ADAPTIVE NETWORK OPTIMIZATIONS
        # ==========================================
        # Disable Nagle's Algorithm (Forces instant packet delivery, fixes 3G latency hangs)
        try: client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        
        # Enable TCP Keep-Alive (Prevents Telco DPI from silently dropping idle connections)
        try: client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        except: pass
        
        # Increase initial read buffer to 64KB for massive payload handling
        request_data = client_socket.recv(65536)
        if not request_data: return
            
        request_str = request_data.decode('utf-8', errors='ignore')
        
        # Connect to backend SSH (Dropbear)
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
        # Apply the same Adaptive Optimizations to the backend socket
        try: server_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        try: server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        except: pass
        
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        # ==========================================
        # 2. DYNAMIC CUSTOM HTTP 101 RESPONSE
        # ==========================================
        custom_resp = "Switching Protocols"
        if os.path.exists(RESP_FILE):
            try:
                with open(RESP_FILE, 'r') as f:
                    content = f.read().strip()
                    if content: custom_resp = content
            except: pass
            
        # Send the HTTP/1.1 101 Upgrade Handshake
        response = f"HTTP/1.1 101 {custom_resp}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))
            
        # TCP Pipelining Catch (Catches early Dropbear SSH handshakes hiding in HTTP headers)
        if b'\r\n\r\n' in request_data:
            leftover = request_data.split(b'\r\n\r\n', 1)[1]
            if leftover: server_socket.sendall(leftover)
        elif b'\n\n' in request_data:
            leftover = request_data.split(b'\n\n', 1)[1]
            if leftover: server_socket.sendall(leftover)
                
        # ==========================================
        # 3. FULL-DUPLEX ADAPTIVE BUFFERING LOOP
        # ==========================================
        while True:
            # 300-second idle timeout prevents dead "zombie" sockets from eating RAM
            r, w, x = select.select([client_socket, server_socket], [], [], 300)
            if not r: break # Connection idle timeout reached, break loop safely
            
            if client_socket in r:
                # recv(65536) automatically adjusts from 1 byte up to 64KB per cycle
                data = client_socket.recv(65536)
                if not data: break
                server_socket.sendall(data)
                
            if server_socket in r:
                data = server_socket.recv(65536)
                if not data: break
                client_socket.sendall(data)
                
    except Exception as e:
        # Silently pass errors (like broken pipes) to prevent thread crashing
        pass
    finally:
        # Ensure mathematically perfect garbage collection on disconnect
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
        # Increased backlog from 100 to 500 to handle massive connection spikes
        server.listen(500)
        print(f"[*] Adaptive Universal Proxy listening on port {port}")
        while True:
            client_sock, addr = server.accept()
            # daemon=True ensures threads close instantly if the main script service is stopped
            threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
    except Exception as e:
        print(f"Failed to bind {port}: {e}")

if __name__ == "__main__":
    # Start Port 80 in a background daemon thread
    threading.Thread(target=start_server, args=(LISTENING_PORTS[0],), daemon=True).start()
    # Start Port 8080 in the main thread to keep the script running
    start_server(LISTENING_PORTS[1])
