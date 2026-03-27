import socket, threading, select

# --- Config ---
LISTENING_PORTS = [80, 8080]
SSH_PORT = 109 

def handle_client(client_socket):
    server_socket = None
    try:
        # Read the initial payload packet
        request_data = client_socket.recv(8192)
        if not request_data:
            return
            
        request_str = request_data.decode('utf-8', errors='ignore')
        
        # Connect to Local SSH (Dropbear)
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        # Handle the Handshake
        if "Upgrade: websocket" in request_str or "Upgrade: Websocket" in request_str:
            client_socket.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        else:
            client_socket.send(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            
        # 🚨 THE FIX: TCP Pipelining Catch
        # Find where the HTTP headers end and forward any appended SSH data
        if b'\r\n\r\n' in request_data:
            leftover = request_data.split(b'\r\n\r\n', 1)[1]
            if leftover:
                server_socket.send(leftover)
        elif b'\n\n' in request_data:
            leftover = request_data.split(b'\n\n', 1)[1]
            if leftover:
                server_socket.send(leftover)
                
        # Start Bi-directional Forwarding
        while True:
            r, w, x = select.select([client_socket, server_socket], [], [])
            if client_socket in r:
                data = client_socket.recv(8192)
                if not data: break
                server_socket.send(data)
            if server_socket in r:
                data = server_socket.recv(8192)
                if not data: break
                client_socket.send(data)
                
    except Exception as e:
        pass
    finally:
        client_socket.close()
        if server_socket:
            server_socket.close()

def start_server(port):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', port))
    server.listen(100)
    print(f"[*] Universal Proxy listening on port {port}")
    
    while True:
        client_sock, addr = server.accept()
        threading.Thread(target=handle_client, args=(client_sock,)).start()

if __name__ == "__main__":
    threading.Thread(target=start_server, args=(LISTENING_PORTS[0],)).start()
    start_server(LISTENING_PORTS[1])
