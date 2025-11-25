"""
Simple HTTP Server for Sensor Test Interface
Serves the sensor_test.html file to avoid CORS issues
"""

import http.server
import socketserver
import os

PORT = 8000
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"🌐 Server running at http://localhost:{PORT}")
        print(f"📂 Serving files from: {DIRECTORY}")
        print(f"\n✅ Open this URL in your browser:")
        print(f"   http://localhost:{PORT}/sensor_test.html")
        print(f"\n⏹️  Press Ctrl+C to stop the server\n")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n🛑 Server stopped")
