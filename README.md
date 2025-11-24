# Digital Photo Frame

A modern digital photo frame application for Raspberry Pi, featuring a Go backend for WebDAV syncing and a native Qt/C++ frontend for smooth performance on low-end hardware (Pi Zero 2W).

## ✨ Features

- **Native Qt Frontend**: Smooth slideshows with cross-fade transitions, optimized for Raspberry Pi Zero 2W.
- **WebDAV Sync**: Automatically sync photos from cloud storage via the Go backend.
- **Multiple Display Modes**: Name/date ordering, random shuffle.
- **Direct Framebuffer**: Runs directly on `linuxfb` without needing X11 or Wayland (though compatible with them).
- **Custom OS Image**: Automated generation of a minimal Raspberry Pi OS Lite image with the application pre-installed.

## 🚀 Quick Install (Raspberry Pi)

### 1. Download Image
Go to the [Releases](../../releases) page and download the latest `raspios-lite-arm64.img.xz`.

### 2. Flash to SD Card
Use a tool like [Raspberry Pi Imager](https://www.raspberrypi.com/software/) or `dd` to flash the image to your SD card.

### 3. Boot
Insert the SD card into your Raspberry Pi (Zero 2W, 3B, 4, 5) and power it on. The application will start automatically.

### 4. Configure
The default configuration expects images in `/opt/digital-photo-frame/images` or configured WebDAV servers.
To configure WebDAV:
1. SSH into the Pi (default user/pass: `pi`/`raspberry` or as configured in the image).
2. Edit `/opt/digital-photo-frame/config.yaml`.
3. Restart the backend: `sudo systemctl restart dpf-backend`.

## 🛠️ Development

### Prerequisites
- Go 1.21+
- Qt 6.2+ (Core, Quick, Network, Qml)
- CMake 3.16+

### Backend (Go)
```bash
cd backend
cp config.yaml.example config.yaml
go run .
```

### Frontend (Qt/C++)
```bash
cd qt-frontend
mkdir build && cd build
cmake ..
make
./appdigital-photo-frame-qt
```

## 📦 Building the OS Image

The repository includes scripts to generate a custom Raspberry Pi OS image.

```bash
# Requires root privileges and ARM64 environment (or emulation)
sudo ./packaging/create_image.sh
```

This script:
1. Downloads the latest Raspberry Pi OS Lite.
2. Installs Qt6 dependencies.
3. Compiles and installs the Go backend and Qt frontend.
4. Sets up systemd services (`dpf-backend` and `dpf-frontend`).

## 🗂️ Project Structure

```
├── backend/                 # Go web server & WebDAV sync
├── qt-frontend/             # Qt/C++ QML application
├── packaging/               # Build and image generation scripts
└── .github/workflows/       # CI/CD for image generation
```

## 📄 License

MIT License
