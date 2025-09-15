# Make Ubuntu Windowsy

Automate turning a fresh Ubuntu GNOME desktop into a Windows-style environment with a single script.

## Overview

This script transforms a default Ubuntu GNOME desktop into a Windows-like interface by:

- **Installing WhiteSur GTK theme & icon pack** - Provides a clean, Windows-inspired visual style
- **Setting up Dash-to-Panel** - Creates a bottom taskbar similar to Windows
- **Configuring system fonts** - Sets Segoe UI as the system font
- **Installing Plank dock** - Adds a macOS-style dock for additional app launching
- **Automatic version detection** - Detects your GNOME Shell version and installs compatible extensions

The script handles all the complex setup automatically, including GNOME Shell extension reloading, so **no logout is required**.

## Features

✅ **Smart version detection** - Automatically detects GNOME Shell version (45, 46, 47, or 48) and installs the correct Dash-to-Panel release
✅ **Complete theming** - WhiteSur GTK theme and icon pack for a cohesive Windows look
✅ **Bottom taskbar** - Dash-to-Panel configured with Windows-style layout and positioning
✅ **System font** - Segoe UI font installation and configuration
✅ **Dock integration** - Plank dock with autostart configuration
✅ **Settings backup** - Automatically backs up your current GNOME settings
✅ **Live reload** - Extensions are reloaded without requiring logout

## Prerequisites

- Ubuntu 24.04+ with GNOME Shell
- GNOME Shell version 45, 46, 47, or 48
- Internet connection for downloading themes and extensions
- No additional PPAs required

## Installation & Usage

1. **Download the script:**

   ```bash
   wget https://raw.githubusercontent.com/yourusername/personal-scripts/main/make-ubuntu-windowsy.sh
   ```

2. **Make it executable:**

   ```bash
   chmod +x make-ubuntu-windowsy.sh
   ```

3. **Run the script:**

   ```bash
   ./make-ubuntu-windowsy.sh
   ```

The script will:

- Prompt for your sudo password (needed for package installation)
- Back up your current GNOME settings
- Install all required packages and themes
- Configure the desktop automatically
- Complete setup without requiring a logout

## What Gets Installed

### Packages

- `git`, `wget`, `unzip`, `make`, `gettext` - Build tools
- `gnome-tweaks` - GNOME customization tool
- `chrome-gnome-shell` - Browser extension support
- `ttf-mscorefonts-installer` - Microsoft fonts including Segoe UI
- `plank` - Dock application

### Themes & Extensions

- **WhiteSur GTK Theme** - Windows-inspired theme
- **WhiteSur Icon Theme** - Matching icon pack
- **Dash-to-Panel** - Bottom taskbar extension (compiled from source)

### Configuration

- Panel positioned at bottom with 48px thickness
- Windows-style button layout and stacking
- Segoe UI system font
- Plank dock configured to autostart

## Troubleshooting

### Extension Not Loading

If Dash-to-Panel doesn't load after installation:

```bash
# Restart GNOME Shell (Alt+F2, type 'r', press Enter)
# Or manually enable the extension:
gnome-extensions enable dash-to-panel@jderose9.github.com
```

### Theme Not Applied

If the WhiteSur theme doesn't appear:

```bash
# Open GNOME Tweaks and manually select:
gnome-tweaks
# Appearance → Themes → Applications: WhiteSur-light
# Appearance → Themes → Shell: WhiteSur-light
# Appearance → Themes → Icons: WhiteSur
```

### Font Issues

If Segoe UI font doesn't apply:

```bash
# Reinstall Microsoft fonts
sudo apt install --reinstall ttf-mscorefonts-installer
# Then reapply font setting
gsettings set org.gnome.desktop.interface font-name 'Segoe UI 10'
```

### GNOME Shell Version Compatibility

The script supports GNOME Shell versions 45-48. If you have a different version:

```bash
# Check your GNOME Shell version
gnome-shell --version

# For unsupported versions, the script will use the default branch
# You may need to manually install a compatible Dash-to-Panel version
```

### Plank Dock Issues

If Plank doesn't start automatically:

```bash
# Start Plank manually
plank &

# Check if autostart file exists
ls ~/.config/autostart/plank.desktop

# Or configure Plank in Startup Applications
gnome-session-properties
```

### Restoring Previous Settings

If you want to revert changes:

```bash
# Restore from backup (replace date with your backup date)
dconf load / < ~/gnome-settings-backup-YYYY-MM-DD.dconf

# Disable extensions manually
gnome-extensions disable dash-to-panel@jderose9.github.com

# Remove installed themes
rm -rf ~/.themes/WhiteSur* ~/.icons/WhiteSur*
```

### Permission Issues

If you encounter permission errors:

```bash
# Ensure script is executable
chmod +x make-ubuntu-windowsy.sh

# Run with proper permissions (script will ask for sudo when needed)
./make-ubuntu-windowsy.sh
```

## Customization

After installation, you can further customize your setup:

- **GNOME Tweaks** - Fine-tune themes, fonts, and extensions
- **Dash-to-Panel Settings** - Access via Extensions app or right-click panel
- **Plank Preferences** - Right-click dock → Preferences

## File Locations

- **Themes:** `~/.themes/WhiteSur-light/`
- **Icons:** `~/.icons/WhiteSur/`
- **Extensions:** `~/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/`
- **Settings Backup:** `~/gnome-settings-backup-YYYY-MM-DD.dconf`
- **Plank Autostart:** `~/.config/autostart/plank.desktop`

## Contributing

Issues and pull requests are welcome! If you encounter problems with specific GNOME Shell versions or have suggestions for improvements, please open an issue.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) by vinceliuice
- [WhiteSur Icon Theme](https://github.com/vinceliuice/WhiteSur-icon-theme) by vinceliuice
- [Dash-to-Panel](https://github.com/home-sweet-gnome/dash-to-panel) by home-sweet-gnome
- [Plank](https://launchpad.net/plank) - Simple, clean dock
