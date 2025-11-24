#!/bin/bash
set -e

# Build Go Backend
echo "Building Go Backend..."
cd backend
go mod download
GOOS=linux GOARCH=arm64 go build -o ../dist/backend_arm64/digital-photo-frame main.go webdav_sync.go config.go
cd ..

# Build Qt Frontend
echo "Building Qt Frontend (Docker ARM64)..."
mkdir -p dist/frontend_arm64

if command -v docker &> /dev/null; then
    echo "Docker found, building in container..."
    docker build -t dpf-builder -f packaging/Dockerfile.build .
    docker run --rm -v "$(pwd):/src" dpf-builder sh -c "mkdir -p /build/build && cmake -S /src/qt-frontend -B /build/build -DCMAKE_BUILD_TYPE=Release && cmake --build /build/build --parallel && cp /build/build/appdigital-photo-frame-qt /src/dist/frontend_arm64/"
else
    echo "Docker not found. Skipping Qt build. Install Docker to build the frontend."
    exit 1
fi

echo "Build complete."
