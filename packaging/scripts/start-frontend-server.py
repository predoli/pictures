#!/usr/bin/env python3

import http.server
import socketserver
import os
import sys
import signal
import threading
import time

# Configuration
FRONTEND_DIR = "/opt/photoframe/frontend"
PORT = 3000

class PhotoFrameHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=FRONTEND_DIR, **kwargs)
    
    def end_headers(self):
        # Add CORS headers to allow backend requests
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        # Cache static assets
        if self.path.endswith(('.js', '.css', '.png', '.jpg', '.jpeg', '.gif', '.ico')):
            self.send_header('Cache-Control', 'public, max-age=3600')
        super().end_headers()

def start_server():
    """Start the HTTP server for the frontend"""
    try:
        with socketserver.TCPServer(("", PORT), PhotoFrameHTTPRequestHandler) as httpd:
            print(f"Starting frontend server at http://localhost:{PORT}")
            print(f"Serving files from: {FRONTEND_DIR}")
            
            # Check if frontend files exist
            index_path = os.path.join(FRONTEND_DIR, "index.html")
            if not os.path.exists(index_path):
                print(f"ERROR: Frontend files not found at {FRONTEND_DIR}")
                print("Make sure the photoframe package is installed correctly.")
                sys.exit(1)
            
            # Graceful shutdown handler
            def signal_handler(sig, frame):
                print("\nShutting down frontend server...")
                httpd.shutdown()
                sys.exit(0)
            
            signal.signal(signal.SIGINT, signal_handler)
            signal.signal(signal.SIGTERM, signal_handler)
            
            # Start server
            httpd.serve_forever()
            
    except OSError as e:
        if e.errno == 98:  # Address already in use
            print(f"ERROR: Port {PORT} is already in use")
            print(f"Try: sudo lsof -i :{PORT}")
        else:
            print(f"ERROR: Failed to start server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    start_server()