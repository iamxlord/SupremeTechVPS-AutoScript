import socket, threading, select

LISTEN_PORT = 2095
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 1194

def handle_client(client_socket):
    target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        # Disable Nagle's Algorithm safely
        try:
            client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            target_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        except: pass
        
        target_socket.connect((TARGET_HOST, TARGET_PORT))
        
        # Send 200 OK to bypass injector limits
        client_socket.sendall(b"HTTP/1.1 200 OK\r\n\r\n")
        
        while True:
            sockets = [client_socket, target_socket]
            r, _, _ = select.select(sockets, [], [])
            if client_socket in r:
                data = client_socket.recv(4096)
                if not data: break
                target_socket.sendall(data)
            if target_socket in r:
                data = target_socket.recv(4096)
                if not data: break
                client_socket.sendall(data)
    except:
        pass
    finally:
        client_socket.close()
        target_socket.close()

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('0.0.0.0', LISTEN_PORT))
        server.listen(100)
        print(f"[*] OHP Listening on {LISTEN_PORT} -> Forwarding to {TARGET_PORT}")
        while True:
            client, addr = server.accept()
            threading.Thread(target=handle_client, args=(client,)).start()
    except Exception as e:
        pass

if __name__ == '__main__':
    start_server()
