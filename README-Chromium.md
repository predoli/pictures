# Digital Photo Frame - Chromium Edition

A Raspberry Pi digital photo frame using Vue.js frontend in Chromium kiosk mode with Go backend.

## Architecture

- **Backend**: Go application serving images via HTTP API
- **Frontend**: Vue.js SPA running in Chromium kiosk mode
- **Display**: Chromium browser in fullscreen kiosk mode

## Features

- **Chromium-based**: Uses native Chromium browser for maximum compatibility
- **Raspberry Pi Optimized**: Works perfectly on Pi 3B and newer
- **Kiosk Mode**: True fullscreen with no browser interface
- **Auto-slideshow**: 15-second intervals with smooth transitions
- **Image Scaling**: Automatic aspect-ratio-preserving scaling
- **HTTP Serving**: Backend serves images via static file endpoints

## Installation

### From Debian Package (Recommended)
```bash
# Download and install
wget photoframe-pi64_*.deb
sudo apt install ./photoframe-pi64_*.deb

# Start the photo frame
photoframe
```

### Manual Installation
```bash
# Install dependencies
sudo apt update
sudo apt install chromium-browser curl

# Install Go backend and Vue.js frontend files manually
# (Copy files to appropriate locations)
```

## Usage

### Simple Start
```bash
# Complete launcher (starts both backend and frontend)
photoframe
```

### Manual Start
```bash
# 1. Start backend
cd /etc/photoframe
/opt/photoframe/digital-photo-frame-aarch64 &

# 2. Wait for backend to start, then start frontend
/usr/local/bin/start-chromium-photoframe.sh
```

## Configuration

### Backend Configuration
Edit `/etc/photoframe/config.yaml`:
```yaml
server:
  host: "0.0.0.0"
  port: "8080"

webdav:
  sync_interval: "5m"
  directories:
    - name: "photos"
      base_url: "https://your-webdav-server.com"
      path: "/photos"
      username: "your-username"
      password: "your-password"
      local_path: "/home/pi/photos"

images:
  supported_formats: [".jpg", ".jpeg", ".png", ".gif", ".bmp"]
  max_file_size: "50MB"
  quality_compression: 85
```

### Display Configuration
The Chromium launcher automatically:
- Detects Raspberry Pi and applies optimizations
- Sets up GPU acceleration when available
- Configures kiosk mode with fullscreen
- Disables browser chrome and popups

## How It Works

1. **Backend**: Go application scans configured directories for images
2. **API**: Serves image metadata and static files via HTTP
3. **Frontend**: Vue.js SPA loads image list from API
4. **Display**: Chromium renders frontend in kiosk mode
5. **Slideshow**: JavaScript timer advances images automatically

## Advantages over Tauri

- ✅ **Better Pi Compatibility**: No GTK/WebKit dependencies
- ✅ **Reliable Fullscreen**: Native Chromium kiosk mode
- ✅ **Hardware Support**: Works with limited OpenGL support
- ✅ **Easier Debugging**: Standard web development tools
- ✅ **Better Performance**: Optimized Chromium rendering
- ✅ **No Build Issues**: No Rust compilation on ARM

## Troubleshooting

### Frontend Issues
```bash
# Check if Chromium is installed
chromium-browser --version

# Check if backend is running
curl http://localhost:8080/images?count=1&ordering=date_asc

# Check frontend files
ls -la /opt/photoframe/frontend/
```

### Display Issues
```bash
# Check X11 display
echo $DISPLAY
xrandr

# Test Chromium manually
chromium-browser --kiosk file:///opt/photoframe/frontend/index.html
```

### Backend Issues
```bash
# Check backend logs
cd /etc/photoframe
/opt/photoframe/digital-photo-frame-aarch64

# Check config
cat /etc/photoframe/config.yaml
```

## Development

### Local Development
```bash
# Start backend
cd backend
go run . 

# Start frontend dev server
cd frontend
npm install
npm run dev

# Frontend will be available at http://localhost:5173
```

### Building
```bash
# Build frontend
cd frontend
npm run build

# Frontend files will be in frontend/dist/
```

## Raspberry Pi Optimizations

The Chromium launcher includes Pi-specific optimizations:
- GPU memory detection and warnings
- Hardware acceleration settings
- Software rendering fallback
- Display optimization flags
- Power management settings

For best performance, ensure:
- GPU memory split: Add `gpu_mem=128` to `/boot/config.txt`
- Hardware acceleration enabled in `raspi-config`
- Sufficient power supply (3A+ recommended)

## Security

- Backend serves only configured image directories
- CORS enabled for frontend access
- No external network access required (except WebDAV sync)
- Chromium runs with restricted permissions in kiosk mode