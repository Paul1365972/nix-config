# Darkness Raspberry Pi Setup (Wayland)

Minimal kiosk environment with labwc, Chromium, and auto-login.

## Installation

```bash
./install.sh
sudo reboot
```

## What's Included

- **UI**: labwc compositor, Waybar panel, Chromium browser
- **Apps**: Thunar, MPV, swaybg
- **Audio**: PipeWire with 4-channel USB support
- **Network**: Tailscale with Taildrop and Taildrive

## Configuration

### Window Manager

Edit `~/.config/labwc/rc.xml` for settings and shortcuts, then:
```bash
labwc --reconfigure
```

Default shortcuts: Alt+Tab, Alt+Shift+Tab, Alt+F4

### Panel

Edit `~/.config/waybar/config` or `~/.config/waybar/style.css`, then:
```bash
pkill waybar && waybar &
```

### Browser

Edit `~/.local/share/applications/chromium-custom.desktop` for Chromium flags.

Verify Wayland mode at `chrome://gpu` (should show "Ozone platform: wayland").

### Wallpaper

Edit `~/.config/labwc/autostart` and change the `swaybg` line:
```bash
swaybg -i /path/to/wallpaper.png -m fill &
```

Modes: stretch, fit, fill, center, tile

### Audio

Set device: `wpctl set-default <id>` (find ID with `wpctl status`)
Test 4-channel: `speaker-test -c 4 -t wav`

### Video Playback

Use `mpv` directly instead of Celluloid to avoid file descriptor leaks.

Celluloid has a bug where it leaks DRM sync_file descriptors (~24/second) when using GPU rendering on Wayland, causing crashes after 2-3 minutes with "Error 24 (Too many open files)".

The included mpv config uses `vo=wlshm` (Wayland shared memory output) which avoids this issue at the cost of higher CPU usage (no GPU acceleration).

### Bluetooth

Pair devices: `./setup-bluetooth.sh`
Manual connect: `bluetoothctl connect <MAC>`

## Key Files

- `~/.bash_profile` - Auto-starts labwc on login
- `~/.config/labwc/autostart` - Launches apps on startup
- `~/.config/labwc/environment` - Wayland environment variables
- `~/.config/mpv/mpv.conf` - Video output configuration
- `~/.asoundrc` + `~/.config/pipewire/` - Audio configuration
- `/etc/sudoers.d/shutdown` - Passwordless shutdown

Tailscale files auto-receive to `~/Downloads/`.
Taildrive mounts at `/mnt/taildrive`.

## Differences from X11 Version

- Native Wayland (no X11 dependencies)
- Built-in compositing (no separate picom process)
- Better performance and lower latency
- No nitrogen GUI (wallpaper via swaybg command)
- Use `WAYLAND_DEBUG=1` for debugging instead of X11 tools

## Troubleshooting

Check compositor logs: `journalctl --user -xe`
Check if process is running: `pgrep labwc`, `pgrep waybar`, `pgrep swaybg`
Verify Wayland display: `echo $WAYLAND_DISPLAY` (should show a value)
Restart PipeWire: `systemctl --user restart pipewire pipewire-pulse wireplumber`
