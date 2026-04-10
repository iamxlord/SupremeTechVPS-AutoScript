import socket, threading, select, os

LISTENING_PORTS = [80, 8080]
SSH_PORT = 109 
RESP_FILE = '/etc/xray/proxy_resp.txt'

def handle_client(client_socket):
    server_socket = None
    try:
        # Disable Nagle's Algorithm safely
        try: client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        
        request_data = client_socket.recv(8192)
        if not request_data: return
            
        request_str = request_data.decode('utf-8', errors='ignore')
        
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try: server_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        # --- DYNAMIC CUSTOM RESPONSE ---
        custom_resp = "Switching Protocols"
        if os.path.exists(RESP_FILE):
            try:
                with open(RESP_FILE, 'r') as f:
                    content = f.read().strip()
                    if content: custom_resp = content
            except: pass
            
        # Send the 101 Upgrade with custom text
        response = f"HTTP/1.1 101 {custom_resp}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
        client_socket.sendall(response.encode('utf-8'))
            
        # TCP Pipelining Catch
        if b'\r\n\r\n' in request_data:
            leftover = request_data.split(b'\r\n\r\n', 1)[1]
            if leftover: server_socket.sendall(leftover)
        elif b'\n\n' in request_data:
            leftover = request_data.split(b'\n\n', 1)[1]
            if leftover: server_socket.sendall(leftover)
                
        # Full-Duplex Bi-Directional Forwarding
        while True:
            r, w, x = select.select([client_socket, server_socket], [], [])
            if client_socket in r:
                data = client_socket.recv(8192)
                if not data: break
                server_socket.sendall(data)
            if server_socket in r:
                data = server_socket.recv(8192)
                if not data: break
                client_socket.sendall(data)
                
    except Exception as e:
        pass
    finally:
        client_socket.close()
        if server_socket: server_socket.close()

def start_server(port):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('0.0.0.0', port))
        server.listen(100)
        print(f"[*] Universal Proxy listening on port {port}")
        while True:
            client_sock, addr = server.accept()
            threading.Thread(target=handle_client, args=(client_sock,)).start()
    except Exception as e:
        print(f"Failed to bind {port}: {e}")

if __name__ == "__main__":
    threading.Thread(target=start_server, args=(LISTENING_PORTS[0],)).start()
    start_server(LISTENING_PORTS[1])
