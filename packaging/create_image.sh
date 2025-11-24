#!/bin/bash
set -e

# Configuration
IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-12-11/2023-12-11-raspios-bookworm-arm64-lite.img.xz"
IMAGE_NAME="raspios-lite-arm64.img"
MOUNT_POINT="/mnt/rpi_root"
LOOP_DEVICE=""

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Install dependencies
apt-get update && apt-get install -y kpartx xz-utils qemu-user-static

# Download Image
if [ ! -f "$IMAGE_NAME" ]; then
    echo "Downloading Raspberry Pi OS Lite..."
    wget -O "$IMAGE_NAME.xz" "$IMAGE_URL"
    unxz "$IMAGE_NAME.xz"
fi

# Expand Image (add 500MB)
echo "Expanding image..."
dd if=/dev/zero bs=1M count=500 >> "$IMAGE_NAME"
parted "$IMAGE_NAME" resizepart 2 100%
losetup -fP "$IMAGE_NAME"
LOOP_DEVICE=$(losetup -j "$IMAGE_NAME" | cut -d: -f1)
e2fsck -f "${LOOP_DEVICE}p2"
resize2fs "${LOOP_DEVICE}p2"

# Mount Image
echo "Mounting image..."
mkdir -p "$MOUNT_POINT"
mount "${LOOP_DEVICE}p2" "$MOUNT_POINT"
mount "${LOOP_DEVICE}p1" "$MOUNT_POINT/boot/firmware"

# Mount binds
mount --bind /dev "$MOUNT_POINT/dev"
mount --bind /sys "$MOUNT_POINT/sys"
mount --bind /proc "$MOUNT_POINT/proc"

# Copy Application Files
echo "Copying application files..."
mkdir -p "$MOUNT_POINT/opt/digital-photo-frame"
cp dist/backend_arm64/digital-photo-frame "$MOUNT_POINT/opt/digital-photo-frame/backend"
cp dist/frontend_arm64/appdigital-photo-frame-qt "$MOUNT_POINT/opt/digital-photo-frame/frontend"
cp backend/config.yaml.example "$MOUNT_POINT/opt/digital-photo-frame/config.yaml"

# Install Dependencies in Chroot
echo "Installing dependencies in chroot..."
cat << EOF | chroot "$MOUNT_POINT"
apt-get update
apt-get install -y qt6-base-dev qt6-declarative-dev qml6-module-qtquick-controls2 qml6-module-qtquick-layouts qml6-module-qtqml-workerscript
EOF

# Configure Systemd Services
echo "Configuring systemd services..."

# Backend Service
cat << EOF > "$MOUNT_POINT/etc/systemd/system/dpf-backend.service"
[Unit]
Description=Digital Photo Frame Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/digital-photo-frame
ExecStart=/opt/digital-photo-frame/backend
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Frontend Service
cat << EOF > "$MOUNT_POINT/etc/systemd/system/dpf-frontend.service"
[Unit]
Description=Digital Photo Frame Frontend
After=dpf-backend.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/digital-photo-frame
ExecStart=/opt/digital-photo-frame/frontend -platform linuxfb
Restart=always
RestartSec=5
Environment=QT_QPA_PLATFORM=linuxfb

[Install]
WantedBy=multi-user.target
EOF

# Enable Services
chroot "$MOUNT_POINT" systemctl enable dpf-backend.service
chroot "$MOUNT_POINT" systemctl enable dpf-frontend.service

# Cleanup
echo "Cleaning up..."
umount "$MOUNT_POINT/dev"
umount "$MOUNT_POINT/sys"
umount "$MOUNT_POINT/proc"
umount "$MOUNT_POINT/boot/firmware"
umount "$MOUNT_POINT"
losetup -d "$LOOP_DEVICE"

echo "Image creation complete: $IMAGE_NAME"
