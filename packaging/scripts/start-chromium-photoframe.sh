#!/bin/bash

# Digital Photo Frame - Chromium Kiosk Mode Launcher
# Starts the Vue.js photo frame frontend in Chromium kiosk mode

set -e

echo "Starting Digital Photo Frame in Chromium..."

# Configuration
FRONTEND_PATH="/opt/photoframe/frontend"
FRONTEND_URL="file://$FRONTEND_PATH/index.html"
CHROMIUM_USER_DATA="/tmp/photoframe-chromium-data"

# Check if frontend files exist
if [ ! -f "$FRONTEND_PATH/index.html" ]; then
    echo "Error: Frontend files not found at $FRONTEND_PATH"
    echo "Make sure the photoframe package is properly installed."
    exit 1
fi

# Clean up any existing Chromium user data
rm -rf "$CHROMIUM_USER_DATA"
mkdir -p "$CHROMIUM_USER_DATA"

# Check for Chromium binary (try different names)
CHROMIUM_BIN=""
for bin in chromium-browser chromium google-chrome chrome; do
    if command -v "$bin" >/dev/null 2>&1; then
        CHROMIUM_BIN="$bin"
        echo "Found Chromium: $CHROMIUM_BIN"
        break
    fi
done

if [ -z "$CHROMIUM_BIN" ]; then
    echo "Error: Chromium browser not found!"
    echo "Please install chromium-browser:"
    echo "  sudo apt install chromium-browser"
    exit 1
fi

# Kill any existing Chromium processes (cleanup)
pkill -f "chromium.*photoframe" 2>/dev/null || true
sleep 1

# Chromium kiosk mode arguments
CHROMIUM_ARGS=(
    --kiosk
    --no-first-run
    --no-default-browser-check
    --disable-infobars
    --disable-session-crashed-bubble
    --disable-restore-session-state
    --disable-dev-shm-usage
    --no-sandbox
    --disable-features=TranslateUI
    --disable-ipc-flooding-protection
    --autoplay-policy=no-user-gesture-required
    --user-data-dir="$CHROMIUM_USER_DATA"
    --allow-file-access-from-files
    --allow-file-access
    --allow-cross-origin-auth-prompt
    --disable-web-security
    --incognito
    --noerrdialogs
    --app="$FRONTEND_URL"
)

# Add GPU/hardware acceleration settings for Raspberry Pi
if [[ -f /proc/device-tree/model ]] && grep -q "Raspberry Pi" /proc/device-tree/model; then
    echo "Detected Raspberry Pi - applying optimizations..."
    
    # Check GPU memory
    if command -v vcgencmd >/dev/null 2>&1; then
        GPU_MEM=$(vcgencmd get_mem gpu | cut -d= -f2 | cut -dM -f1)
        echo "GPU Memory: ${GPU_MEM}M"
        
        if [ "$GPU_MEM" -lt 64 ]; then
            echo "Warning: Low GPU memory. Consider adding 'gpu_mem=128' to /boot/config.txt"
        fi
    fi
    
    # Pi-specific optimizations
    CHROMIUM_ARGS+=(
        --disable-gpu-process-crash-limit
        --disable-software-rasterizer
        --enable-gpu-rasterization
        --disable-background-timer-throttling
        --disable-backgrounding-occluded-windows
        --disable-renderer-backgrounding
    )
fi

# Set display if not set
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi

echo "Launching Chromium with frontend at: $FRONTEND_URL"
echo "Display: $DISPLAY"
echo "Chromium binary: $CHROMIUM_BIN"
echo "Arguments: ${CHROMIUM_ARGS[*]}"

# Check if backend is accessible before starting Chromium
echo "Checking backend connectivity..."
if curl -s --connect-timeout 5 "http://localhost:8080/images?count=1&ordering=date_asc" >/dev/null 2>&1; then
    echo "✅ Backend is accessible"
else
    echo "⚠️  Warning: Backend not accessible at http://localhost:8080"
    echo "   The photo frame may not display images until backend is started"
fi

# Start Chromium in kiosk mode
echo "Starting Chromium..."
exec "$CHROMIUM_BIN" "${CHROMIUM_ARGS[@]}"