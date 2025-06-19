# Digital Photo Frame

A modern digital photo frame application with web interface and optional desktop app, designed for Raspberry Pi.

## ✨ Features

- **Web Interface**: Clean, responsive photo display
- **WebDAV Sync**: Automatically sync photos from cloud storage
- **Multiple Display Modes**: Name/date ordering, random shuffle
- **Pagination**: Navigate through large photo collections
- **Base64 API**: Efficient photo serving via REST API
- **Raspberry Pi Optimized**: Native ARM builds for all Pi models
- **Auto-start Service**: Runs on boot with systemd
- **Desktop App**: Optional Tauri-based desktop application

## 🚀 Quick Install (Raspberry Pi)

### 1. Download & Install
```bash
# Pi Zero
wget https://github.com/yourrepo/releases/latest/download/photoframe-pi-zero_*.deb
sudo apt install ./photoframe-pi-zero_*.deb

# Pi 3/4
wget https://github.com/yourrepo/releases/latest/download/photoframe-pi_*.deb
sudo apt install ./photoframe-pi_*.deb

# Pi 64-bit
wget https://github.com/yourrepo/releases/latest/download/photoframe-pi64_*.deb
sudo apt install ./photoframe-pi64_*.deb
```

### 2. Configure
```bash
# Edit configuration
sudo nano /etc/photoframe/config.yaml

# Restart service
sudo systemctl restart photoframe
```

### 3. Access
Open `http://your-pi-ip:8080` in any web browser

## ⚙️ Configuration

Edit `/etc/photoframe/config.yaml`:

```yaml
server:
  host: "0.0.0.0"  # Listen on all interfaces
  port: 8080       # Web server port

directories:
  - path: "/var/lib/photoframe/images"

webdav:
  sync_interval: "1h"
  servers:
    - url: "https://your-webdav-server.com"
      username: "your-username"
      password: "your-password"
      remote_path: "/photos"
      local_path: "/var/lib/photoframe/images/webdav"

logging:
  level: "info"
```

## 🛠️ Service Management

```bash
# Control service
sudo systemctl start photoframe
sudo systemctl stop photoframe
sudo systemctl restart photoframe
sudo systemctl status photoframe

# View logs
sudo journalctl -u photoframe -f

# Uninstall
sudo apt remove photoframe-pi-zero  # or photoframe-pi, photoframe-pi64
```

## 🏗️ Development

### Prerequisites
- Go 1.23+
- Node.js 18+
- Rust (for desktop app)

### Backend
```bash
cd backend
cp config.yaml.example config.yaml
# Edit config.yaml for your setup
go run .
```

### Frontend
```bash
cd frontend
npm install
npm run dev          # Web development
npm run tauri:dev    # Desktop app development
```

### Building
```bash
# Backend
cd backend
go build -o digital-photo-frame .

# Web frontend
cd frontend
npm run build

# Desktop app
npm run tauri:build
```

## 📡 API

### Get Images
```
GET /images?count=10&ordering=random&last_image=photo.jpg
```

**Parameters:**
- `count`: Number of images to return
- `ordering`: `name_asc`, `name_desc`, `date_asc`, `date_desc`, `random`
- `last_image`: For pagination (continuation)

**Response:**
```json
{
  "images": [
    {
      "name": "photo.jpg",
      "data": "base64-encoded-image",
      "modTime": "2023-01-01T00:00:00Z"
    }
  ]
}
```

## 🗂️ Project Structure

```
├── backend/                 # Go web server
│   ├── main.go             # Entry point
│   ├── config.go           # Configuration handling
│   ├── webdav_sync.go      # WebDAV synchronization
│   └── config.yaml.example # Config template
├── frontend/               # Vue.js web app
│   ├── src/                # Vue components
│   ├── src-tauri/          # Tauri desktop wrapper
│   └── dist/               # Built web files
├── packaging/              # Debian package files
│   ├── systemd/            # Systemd service
│   ├── debian/             # Install scripts
│   └── wrapper/            # Binary wrapper
└── .github/workflows/      # CI/CD
```

## 🎯 Supported Platforms

**Debian Packages:**
- Raspberry Pi Zero (ARMv6)
- Raspberry Pi 3/4 (ARMv7)
- Raspberry Pi 64-bit (ARM64)

**Manual Build:**
- Linux x86_64
- macOS (development)
- Windows (development)

## 🔄 Auto-sync

Configure WebDAV servers to automatically sync photos:

1. Edit `/etc/photoframe/config.yaml`
2. Add your WebDAV server details
3. Photos sync every hour (configurable)
4. New photos appear automatically

## 🖥️ Desktop App

Optional Tauri-based desktop application for development and testing:

```bash
cd frontend
npm run tauri:dev    # Development
npm run tauri:build  # Production build
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature-name`
3. Make changes and test
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- [Build Guide](BUILD.md)
- [API Documentation](backend/openapi.yaml)
- [Releases](../../releases)
- [Issues](../../issues)
