#!/bin/bash

# Build script for digital photo frame frontend (Tauri app)
# Supports cross-compilation for multiple platforms

set -e

OUTPUT_DIR="./target"

echo "Building digital photo frame frontend..."

# Ensure dependencies are installed
echo "Installing dependencies..."
npm install

# Build for current platform (development)
echo "Building for current platform..."
npm run tauri:build

echo ""
echo "Setting up cross-compilation for ARM targets..."

# Add ARM targets for Rust cross-compilation
echo "Adding ARM targets..."
rustup target add armv7-unknown-linux-gnueabihf  # ARM v7 (Pi 3/4)
rustup target add aarch64-unknown-linux-gnu      # ARM64 (Pi 64-bit)

# Install cross-compilation tools
echo "Installing cross-compilation dependencies..."
# For ARM v7
if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "WARNING: arm-linux-gnueabihf-gcc not found. Install with:"
    echo "  macOS: brew install arm-linux-gnueabihf-gcc"
    echo "  Ubuntu: sudo apt-get install gcc-arm-linux-gnueabihf"
fi

# For ARM64
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "WARNING: aarch64-linux-gnu-gcc not found. Install with:"
    echo "  macOS: brew install aarch64-elf-gcc"
    echo "  Ubuntu: sudo apt-get install gcc-aarch64-linux-gnu"
fi

echo ""
echo "To build for Raspberry Pi, first install cross-compilation tools, then run:"
echo ""
echo "For Raspberry Pi 3/4 (ARM v7):"
echo "  npm run tauri:build -- --target armv7-unknown-linux-gnueabihf"
echo ""
echo "For Raspberry Pi 64-bit (ARM64):"
echo "  npm run tauri:build -- --target aarch64-unknown-linux-gnu"
echo ""
echo "Built binaries will be in: src-tauri/target/[TARGET]/release/"