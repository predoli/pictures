# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a digital photo frame backend built in Go using the Gin web framework. The application serves images via a REST API with base64 encoding and automatically synchronizes images from WebDAV servers.

## Architecture

- **main.go**: Entry point and HTTP server setup with Gin routes
- **config.go**: Configuration loading from YAML files
- **webdav_sync.go**: WebDAV client implementation for periodic synchronization
- **openapi.yaml**: API specification for the image serving endpoint

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

## Development Commands

### Build and Run
```bash
go mod tidy          # Download dependencies
go run .             # Run the server
go build -o photoframe .  # Build binary
```

### Testing
```bash
# Test the API endpoint
curl "http://localhost:8080/images?count=5&ordering=name_asc"
```

### Configuration
- Edit `config.yaml` to configure WebDAV servers and local directories
- Ensure WebDAV credentials are properly configured
- Local image directories are created automatically during sync

## Dependencies

- **github.com/gin-gonic/gin**: HTTP web framework
- **github.com/studio-b12/gowebdav**: WebDAV client library
- **gopkg.in/yaml.v3**: YAML configuration parsing

## Image Processing

Images are loaded into memory and base64-encoded for JSON response. The application supports common image formats (JPEG, PNG, GIF, WebP, BMP) as defined in the configuration.