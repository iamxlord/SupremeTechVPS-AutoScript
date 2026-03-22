# TheTechSavage OHP (Open HTTP Proxy)
import socket, threading, select

# Listen on 2095 (OHP) -> Forward to 1194 (OpenVPN) or 22 (SSH)
LISTEN_PORT = 2095
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 1194 # Default to OpenVPN

def handle_client(client_socket):
    target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        target_socket.connect((TARGET_HOST, TARGET_PORT))
        # Send 200 OK to trick the injector
        client_socket.send(b"HTTP/1.1 200 OK\r\n\r\n")
        
        while True:
            sockets = [client_socket, target_socket]
            r, _, _ = select.select(sockets, [], [])
            if client_socket in r:
                data = client_socket.recv(4096)
                if not data: break
                target_socket.send(data)
            if target_socket in r:
                data = target_socket.recv(4096)
                if not data: break
                client_socket.send(data)
    except:
        pass
    finally:
        client_socket.close()
        target_socket.close()

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(('0.0.0.0', LISTEN_PORT))
    server.listen(100)
    print(f"[*] OHP Listening on {LISTEN_PORT} -> Forwarding to {TARGET_PORT}")
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client,)).start()

if __name__ == '__main__':
    start_server()
