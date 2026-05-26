#!/bin/bash
#
# Raspberry Pi Setup Script for Darkness
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

echo "========================================="
echo "Darkness Wayland Raspberry Pi Setup"
echo "========================================="

[ -d "$CONFIG_DIR" ] || { echo "Error: Config directory not found"; exit 1; }

echo "[1/10] Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "[2/10] Installing packages..."
sudo apt install -y labwc waybar swaybg wl-clipboard \
    chromium thunar mpv papirus-icon-theme \
    pipewire pipewire-alsa pipewire-pulse wireplumber rclone fuse

echo "[3/10] Enabling services..."
sudo systemctl enable --now bluetooth
sudo rfkill unblock bluetooth
sudo raspi-config nonint do_boot_behaviour B2
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "[4/10] Creating directories..."
mkdir -p ~/.config/{labwc,waybar,mpv,pipewire/pipewire.conf.d,pipewire/client.conf.d,systemd/user} \
    ~/.local/share/applications ~/Pictures ~/Downloads

echo "[5/10] Installing configurations..."
cp "$CONFIG_DIR/labwc/autostart" ~/.config/labwc/autostart
cp "$CONFIG_DIR/labwc/rc.xml" ~/.config/labwc/rc.xml
cp "$CONFIG_DIR/labwc/environment" ~/.config/labwc/environment
cp "$CONFIG_DIR/waybar/config" ~/.config/waybar/config
cp "$CONFIG_DIR/waybar/style.css" ~/.config/waybar/style.css
cp "$CONFIG_DIR/mpv/mpv.conf" ~/.config/mpv/mpv.conf
cp "$CONFIG_DIR/applications/"* ~/.local/share/applications/
cp "$CONFIG_DIR/asoundrc" ~/.asoundrc
cp "$CONFIG_DIR/pipewire/pipewire.conf.d/"* ~/.config/pipewire/pipewire.conf.d/
cp "$CONFIG_DIR/pipewire/client.conf.d/"* ~/.config/pipewire/client.conf.d/
cp "$CONFIG_DIR/systemd/user/"* ~/.config/systemd/user/

echo "[6/10] Configuring configurations..."

chmod +x ~/.config/labwc/autostart

cp "$SCRIPT_DIR/wallpaper/megumin_wallpaper.png" ~/Pictures/

if ! grep -q "exec labwc" ~/.profile; then
cat >> ~/.profile <<'EOF'

if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec labwc
fi
EOF
fi

echo "[7/10] Configuring passwordless shutdown..."
sudo cp "$CONFIG_DIR/sudoers_shutdown" /etc/sudoers.d/shutdown
sudo chmod 0440 /etc/sudoers.d/shutdown

echo "[8/10] Installing Tailscale..."
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

if ! sudo tailscale status &> /dev/null; then
    echo "Authenticating Tailscale (check your browser)..."
    sudo tailscale up
fi

echo "Setting Tailscale operator to current user..."
sudo tailscale set --operator=$USER

echo "[9/10] Configuring Taildrop..."
sudo cp "$CONFIG_DIR/systemd/user/tailreceive.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now tailreceive

echo "[10/10] Configuring Taildrive rclone mount..."
sudo mkdir -p /mnt/taildrive

if ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
fi

sudo cp "$CONFIG_DIR/systemd/system/mnt-taildrive.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mnt-taildrive.service

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Reboot to start: sudo reboot"
echo "Optional: Set default audio device with 'wpctl set-default <device-id>' (use 'wpctl status' to find device ID, most likely 32)"
echo "Optional: Run setup-bluetooth.sh to pair devices"
echo ""
