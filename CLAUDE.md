# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a digital photo frame application with both backend (Go) and frontend (Vue.js) components. The backend serves images via REST API with WebDAV synchronization, while the frontend provides web interfaces.

## Architecture

### Backend (Go)
- **main.go**: Entry point and HTTP server setup with Gin routes
- **config.go**: Configuration loading from YAML files
- **webdav_sync.go**: WebDAV client implementation for periodic synchronization
- **openapi.yaml**: API specification for the image serving endpoint

### Frontend (Vue.js)
- **src/**: Vue.js components and composables
- **dist/**: Built web files served by backend

### Packaging
- **packaging/**: Debian package configuration
- **packaging/systemd/**: systemd service files
- **packaging/debian/**: Package installation scripts
- **.github/workflows/**: CI/CD for automated releases

## Key Components

### Configuration System
The application loads configuration from `config.yaml` which defines:
- Server settings (host, port)
- WebDAV directories to synchronize
- Image format support and processing settings
- Logging configuration

### WebDAV Synchronization
- Periodically syncs images from configured WebDAV servers
- Downloads new/updated images to local directories
- Removes local files that no longer exist remotely
- Configurable sync interval via `webdav.sync_interval`

### Image API
- Single endpoint `/images` that returns base64-encoded images
- Supports ordering by name (asc/desc), date (asc/desc), or random
- Pagination support with `count` parameter
- Continuation support with `last_image` parameter

### Frontend Modes
- **Web Interface**: Responsive browser-based photo frame
- **Auto-switching**: Configurable display modes and timing

## Development Commands

### Backend
```bash
cd backend
cp config.yaml.example config.yaml
# Edit config.yaml for your setup
go mod tidy          # Download dependencies
go run .             # Run the server
go build -o digital-photo-frame .  # Build binary
```

### Frontend
```bash
cd frontend
npm install          # Install dependencies
npm run dev          # Web development server
npm run build        # Build web version
```

### Testing
```bash
# Test the API endpoint
curl "http://localhost:8080/images?count=5&ordering=name_asc"

# Test web interface
open http://localhost:8080
```

### Packaging
```bash
# Create release (triggers GitHub Actions)
git tag v1.0.0
git push origin v1.0.0

# Manual package testing
cd packaging
./test-package.sh  # If available
```

## Configuration

### Backend Configuration
- Main config: `backend/config.yaml` (copy from `config.yaml.example`)
- Production config: `/etc/photoframe/config.yaml` (on installed systems)
- Image directories: Configurable, defaults to `./images`
- WebDAV servers: Optional, for automatic photo sync

### Frontend Configuration
- Vite config: `frontend/vite.config.ts`
- Build target: Depends on platform (web always)

## Dependencies

### Backend
- **github.com/gin-gonic/gin**: HTTP web framework
- **github.com/studio-b12/gowebdav**: WebDAV client library
- **gopkg.in/yaml.v3**: YAML configuration parsing

### Frontend
- **Vue 3**: Frontend framework
- **TypeScript**: Type safety
- **Vite**: Build tool

### Packaging
- **fpm**: Ruby gem for creating Debian packages
- **systemd**: Service management on Linux

## Deployment

### Development
- Backend runs on `localhost:8080`
- Frontend dev server on `localhost:1420` (Vite default)

### Production (Raspberry Pi)
- Backend service: `photoframe.service`
- Frontend service: `photoframe-frontend.service` (fullscreen)
- Package installation: `.deb` files via GitHub releases
- Auto-start: systemd services enabled by default

## File Structure

```
├── backend/                 # Go web server
│   ├── main.go             # Entry point
│   ├── config.go           # Configuration
│   ├── webdav_sync.go      # WebDAV sync
│   ├── config.yaml.example # Config template
│   └── .gitignore          # Excludes images and binaries
├── frontend/               # Vue.js web app
│   ├── src/                # Vue components
│   ├── dist/               # Built files (gitignored)
│   └── .gitignore          # Excludes build artifacts
├── packaging/              # Debian packaging
│   ├── systemd/            # Service definitions
│   ├── debian/             # Install/remove scripts
│   └── wrapper/            # Binary wrapper scripts
├── .github/workflows/      # CI/CD automation
└── README.md              # User documentation
```

## Image Processing

Images are loaded into memory and base64-encoded for JSON response. The application supports common image formats (JPEG, PNG, GIF, WebP, BMP, HEIC) as defined in the configuration.

## Security Considerations

- WebDAV credentials stored in config files (ensure proper permissions)
- Systemd services run as dedicated `photoframe` user
- File access restricted to necessary directories
- No authentication on web interface (intended for private networks)

## Common Issues

### Service Won't Start
- Check systemd service status: `systemctl status photoframe.service`
- Verify binary exists: `ls -la /usr/bin/digital-photo-frame`
- Check config file: `cat /etc/photoframe/config.yaml`
- Working directory must contain config.yaml

### Frontend Not Building
- Web interface always available via backend

### WebDAV Sync Issues
- Check network connectivity and credentials
- Verify WebDAV server supports required operations
- Monitor logs: `journalctl -u photoframe.service -f`