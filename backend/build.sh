#!/bin/bash

# Build script for digital photo frame backend
# Supports cross-compilation for multiple platforms

set -e

BINARY_NAME="digital-photo-frame"
OUTPUT_DIR="./bin"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Building digital photo frame backend..."

# Build for current platform (development)
echo "Building for current platform..."
go build -o "$OUTPUT_DIR/$BINARY_NAME" .

# Build for Raspberry Pi Zero (ARM v6)
echo "Building for Raspberry Pi Zero (ARM v6)..."
GOOS=linux GOARCH=arm GOARM=6 go build -o "$OUTPUT_DIR/${BINARY_NAME}-pi-zero" .

# Build for Raspberry Pi 3/4 (ARM v7)
echo "Building for Raspberry Pi 3/4 (ARM v7)..."
GOOS=linux GOARCH=arm GOARM=7 go build -o "$OUTPUT_DIR/${BINARY_NAME}-pi-3-4" .

# Build for Raspberry Pi 64-bit (ARM64)
echo "Building for Raspberry Pi 64-bit (ARM64)..."
GOOS=linux GOARCH=arm64 go build -o "$OUTPUT_DIR/${BINARY_NAME}-pi-64" .

echo "Build complete! Binaries available in $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR"

echo ""
echo "Target binary for Raspberry Pi Zero: $OUTPUT_DIR/${BINARY_NAME}-pi-zero"