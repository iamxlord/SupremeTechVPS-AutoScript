import socket, threading, select

# --- Config ---
# Listen on both standard HTTP and Proxy ports
LISTENING_PORTS = [80, 8080]
# Forward to Dropbear SSH
SSH_PORT = 109 

# --- Logic ---
def handle_client(client_socket):
    server_socket = None
    try:
        # Read the initial payload
        request = client_socket.recv(4096).decode('utf-8', errors='ignore')
        
        # Connect to Local SSH (Dropbear)
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect(('127.0.0.1', SSH_PORT))
        
        # Check if it's a WebSocket request
        if "Upgrade: websocket" in request or "Upgrade: Websocket" in request:
            response = "HTTP/1.1 101 Switching Protocols\r\n" \
                       "Upgrade: websocket\r\n" \
                       "Connection: Upgrade\r\n\r\n"
            client_socket.send(response.encode('utf-8'))
        else:
            # For strange payloads, HTTP Injector, or standard proxy requests
            # We blindly approve the connection to establish the SSH tunnel
            response = "HTTP/1.1 200 Connection Established\r\n\r\n"
            client_socket.send(response.encode('utf-8'))
        
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
    # Prevent "Address already in use" errors
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', port))
    server.listen(100)
    print(f"[*] Universal Proxy listening on port {port}")
    
    while True:
        client_sock, addr = server.accept()
        threading.Thread(target=handle_client, args=(client_sock,)).start()

if __name__ == "__main__":
    # Start a thread for Port 80
    threading.Thread(target=start_server, args=(LISTENING_PORTS[0],)).start()
    # Run Port 8080 on the main thread to keep script alive
    start_server(LISTENING_PORTS[1])
