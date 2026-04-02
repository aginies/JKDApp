import http.server
import socketserver
import os
import socket
from datetime import datetime

# Configuration
PORT = 8001
DIRECTORY = "build/app/outputs/flutter-apk/"

if not os.path.exists(DIRECTORY):
    os.makedirs(DIRECTORY)


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=DIRECTORY, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def version_string(self):
        return "JKDApp HTTP Server/1.0"

    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {args[0]}")

    def do_GET(self):
        try:
            if self.path == "/":
                self.serve_directory_index()
                return
            return super().do_GET()
        except Exception as e:
            self.send_error(500, f"Internal error: {str(e)}")

    def serve_directory_index(self):
        try:
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()

            files = []
            for entry in os.scandir(self.directory):
                if entry.is_file():
                    stat = entry.stat()
                    files.append(
                        {
                            "name": os.path.basename(entry.path),
                            "size": self.format_size(stat.st_size),
                            "date": datetime.fromtimestamp(stat.st_mtime).strftime(
                                "%Y-%m-%d %H:%M"
                            ),
                            "url": entry.path.replace(DIRECTORY, "").lstrip("/"),
                        }
                    )
            files.sort(key=lambda x: x["name"])

            html = self.format_html(files)
            self.wfile.write(html.encode("utf-8"))
        except Exception as e:
            self.send_error(500, f"Failed to list files: {str(e)}")

    def format_size(self, size):
        for unit in ["B", "KB", "MB", "GB"]:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} TB"

    def format_html(self, files):
        return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JKDApp APK Downloads</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 30px;
            background: #fafafa;
            color: #1a1a1a;
        }}
        h1 {{
            font-size: 2em;
            color: #2c3e50;
            margin-bottom: 30px;
            text-align: center;
        }}
        .file-list {{
            display: grid;
            gap: 15px;
        }}
        .file-item {{
            background: white;
            padding: 20px 25px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: box-shadow 0.2s;
        }}
        .file-item:hover {{
            box-shadow: 0 4px 16px rgba(0,0,0,0.12);
        }}
        .file-info {{
            flex: 1;
        }}
        .file-name {{
            font-size: 1.3em;
            font-weight: 600;
            margin-bottom: 8px;
            color: #2c3e50;
            word-break: break-all;
        }}
        .file-date {{
            font-size: 1em;
            color: #666;
        }}
        .file-meta {{
            display: flex;
            gap: 20px;
            align-items: center;
            padding-left: 25px;
        }}
        .file-size {{
            font-size: 0.95em;
            color: #888;
            background: #f0f0f0;
            padding: 6px 14px;
            border-radius: 6px;
        }}
        .download-btn {{
            background: #3498db;
            color: white;
            text-decoration: none;
            padding: 12px 30px;
            border-radius: 8px;
            font-size: 1.05em;
            font-weight: 500;
            transition: background 0.2s;
        }}
        .download-btn:hover {{
            background: #2980b9;
        }}
        .empty {{
            text-align: center;
            padding: 60px 20px;
            color: #888;
            font-size: 1.1em;
        }}
    </style>
</head>
<body>
    <h1>📱 JKDApp APK Downloads</h1>
    <div class="file-list">
        {
            "".join(
                f'''
        <div class="file-item">
            <div class="file-info">
                <div class="file-name">{f["name"]}</div>
                <div class="file-date">📅 Available since: {f["date"]}</div>
            </div>
            <div class="file-meta">
                <span class="file-size">{f["size"]}</span>
                <a href="{f["url"]}" class="download-btn">⬇ Download</a>
            </div>
        </div>'''
                for f in files
            )
            if files
            else '<div class="empty">No APK files available</div>'
        }
    </div>
</body>
</html>"""


class CustomTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "localhost"


def main():
    local_ip = get_local_ip()

    print(f"\n{'=' * 60}")
    print(f"🚀 Starting JKDApp APK Server")
    print(f"{'=' * 60}")
    print(f"📁 Directory: {DIRECTORY}")
    print(f"🌐 Local URL: http://{local_ip}:{PORT}")
    print(f"🔒 Status: Ready to serve")
    print(f"{'=' * 60}")
    print("⌨️  Press Ctrl+C to stop\n")

    try:
        with CustomTCPServer(("", PORT), Handler) as httpd:
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                pass
    except OSError as e:
        if "Address already in use" in str(e):
            print(f"❌ Port {PORT} is already in use")
            print(f"💡 Try changing PORT in share_http.py")
        else:
            print(f"❌ Network error: {e}")
    except Exception as e:
        print(f"❌ Server error: {e}")
    print(f"\n🛑 Server stopped")


if __name__ == "__main__":
    main()
