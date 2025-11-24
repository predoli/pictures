#!/bin/bash
set -e

# Build Go Backend
echo "Building Go Backend..."
cd backend
GOOS=linux GOARCH=arm64 go build -o ../dist/backend_arm64/digital-photo-frame main.go webdav_sync.go config.go
# GOOS=linux GOARCH=arm go build -o ../dist/backend_armhf/digital-photo-frame main.go webdav_sync.go config.go
cd ..

# Build Qt Frontend
# Note: This assumes a cross-compilation environment or running on ARM
# For CI, we might need to use a container.
# Here we just define the steps.
echo "Building Qt Frontend..."
mkdir -p qt-frontend/build
cd qt-frontend/build
# cmake .. -DCMAKE_BUILD_TYPE=Release
# make -j$(nproc)
# cp appdigital-photo-frame-qt ../../dist/frontend_arm64/
cd ../..

echo "Build complete."
