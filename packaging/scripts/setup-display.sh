#!/bin/bash
# Setup script for photo frame display configuration

echo "Setting up display for photo frame..."

# Enable auto-login for photoframe user
sudo raspi-config nonint do_boot_behaviour B2

# Configure X11 to start automatically
if [ ! -f /home/photoframe/.xsession ]; then
    sudo -u photoframe mkdir -p /home/photoframe
    sudo -u photoframe cat > /home/photoframe/.xsession << 'EOF'
#!/bin/bash
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor after 1 second
unclutter -idle 1 &

# Start window manager (lightweight)
openbox-session
EOF
    sudo chmod +x /home/photoframe/.xsession
fi

# Install required packages for GUI
apt-get update
apt-get install -y xinit xserver-xorg lightdm openbox unclutter

# Configure lightdm for auto-login
cat > /etc/lightdm/lightdm.conf << 'EOF'
[Seat:*]
autologin-user=photoframe
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

echo "Display setup complete. Reboot required for auto-login to take effect."