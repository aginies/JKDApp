import http.server
import socketserver
import os
import socket

# Configuration
PORT = 8001
DIRECTORY = "build/app/outputs/flutter-apk/"  # The folder you want to share

# Create the directory if it doesn't exist
if not os.path.exists(DIRECTORY):
    os.makedirs(DIRECTORY)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Tell the handler to serve files from our specific directory
        super().__init__(*args, directory=DIRECTORY, **kwargs)

# Improved server that allows immediate port reuse
class CustomTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

# Get local IP for better display
def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "localhost"

local_ip = get_local_ip()

print(f"Starting server for directory: {DIRECTORY}")
try:
    with CustomTCPServer(("", PORT), Handler) as httpd:
        print(f"Serving at http://{local_ip}:{PORT}")
        print("Press Ctrl+C to stop and release the port.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")
            httpd.shutdown()
except Exception as e:
    print(f"Error starting server: {e}")
finally:
    print("Server stopped and port closed.")

