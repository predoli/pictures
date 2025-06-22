#!/bin/bash

# Complete Photo Frame Launcher
# Starts both backend and frontend, then launches Chromium

set -e

echo "=== Digital Photo Frame Launcher ==="

# Paths
BACKEND_CONFIG="/etc/photoframe/config.yaml"
BACKEND_BIN="/opt/photoframe/digital-photo-frame-aarch64"
FRONTEND_LAUNCHER="/usr/local/bin/start-chromium-photoframe.sh"

# Check if backend exists
if [ ! -f "$BACKEND_BIN" ]; then
    echo "Error: Backend binary not found at $BACKEND_BIN"
    exit 1
fi

# Check if config exists
if [ ! -f "$BACKEND_CONFIG" ]; then
    echo "Error: Backend config not found at $BACKEND_CONFIG"
    echo "Please create the config file first."
    exit 1
fi

# Function to wait for backend
wait_for_backend() {
    echo "Waiting for backend to start..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "http://localhost:8080/images?count=1&ordering=date_asc" >/dev/null 2>&1; then
            echo "Backend is ready!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo "Attempt $attempt/$max_attempts - waiting for backend..."
        sleep 2
    done
    
    echo "Error: Backend failed to start within 60 seconds"
    return 1
}

# Start backend in background
echo "Starting backend..."
cd "$(dirname "$BACKEND_CONFIG")"
"$BACKEND_BIN" &
BACKEND_PID=$!

# Wait for backend to be ready
if ! wait_for_backend; then
    echo "Killing backend process..."
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

echo "Backend started successfully (PID: $BACKEND_PID)"

# Start frontend
echo "Starting Chromium frontend..."
if [ -f "$FRONTEND_LAUNCHER" ]; then
    exec "$FRONTEND_LAUNCHER"
else
    echo "Error: Frontend launcher not found at $FRONTEND_LAUNCHER"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi