# Build & Deployment Guide

## 🚀 Recommended: Debian Package Installation

The easiest way to deploy on Raspberry Pi is using pre-built Debian packages:

### 1. Create a Release
```bash
git tag v1.0.0
git push origin v1.0.0
```

### 2. Download & Install
Go to your GitHub releases page and download the appropriate package:

```bash
# Pi Zero
wget https://github.com/yourrepo/releases/download/v1.0.0/photoframe-pi-zero_1.0.0_armhf.deb
sudo apt install ./photoframe-pi-zero_1.0.0_armhf.deb

# Pi 3/4
wget https://github.com/yourrepo/releases/download/v1.0.0/photoframe-pi_1.0.0_armhf.deb
sudo apt install ./photoframe-pi_1.0.0_armhf.deb

# Pi 64-bit
wget https://github.com/yourrepo/releases/download/v1.0.0/photoframe-pi64_1.0.0_arm64.deb
sudo apt install ./photoframe-pi64_1.0.0_arm64.deb
```

### 3. Configure & Access
```bash
# Edit configuration
sudo nano /etc/photoframe/config.yaml

# Restart service
sudo systemctl restart photoframe

# Access web interface
http://your-pi-ip:8080
```

The package automatically:
- Creates `photoframe` user
- Sets up systemd service (auto-starts on boot)
- Creates all needed directories
- Installs web frontend

---

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

---

## 🏗️ Local Development

### Backend (Go)
```bash
cd backend
cp config.yaml.example config.yaml
# Edit config.yaml for your setup
go run .
```

### Frontend (Vue + Tauri)
```bash
cd frontend
npm install
npm run dev          # Web development
npm run tauri:dev    # Desktop app development
npm run build        # Build web version
npm run tauri:build  # Build desktop app
```

**Built files:**
- Backend: `backend/digital-photo-frame` (after `go build`)
- Web frontend: `frontend/dist/` (after `npm run build`)
- Desktop app: `frontend/src-tauri/target/release/photo-frame` (after `npm run tauri:build`)

Access development server at `http://localhost:8080`

---

## 📦 Package Contents

The Debian packages include:
- **Binary**: `/opt/photoframe/digital-photo-frame-{arch}`
- **Web frontend**: `/opt/photoframe/` (built Vue.js app)
- **Configuration**: `/etc/photoframe/config.yaml`
- **Data directory**: `/var/lib/photoframe/images/`
- **Systemd service**: Auto-start on boot
- **User**: Dedicated `photoframe` system user

---

## 🔧 Manual Build (Advanced)

If you need to build manually:

```bash
# Backend for Pi Zero
cd backend
GOOS=linux GOARCH=arm GOARM=6 go build -o digital-photo-frame-pi-zero .

# Frontend
cd frontend
npm install
npm run build
```

The Debian package approach is recommended for production deployments.