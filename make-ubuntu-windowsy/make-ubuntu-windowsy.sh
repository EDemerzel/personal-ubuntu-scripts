#!/usr/bin/env bash

# Description:
#   Automate turning a fresh Ubuntu GNOME desktop into a Windows‑style environment.
#   Compatible with Ubuntu 24.04, 24.10, and 25.04.
#
# Features:
#   • Applies the WhiteSur GTK theme & icon pack
#   • Installs & enables Dash‑to‑Panel (bottom taskbar) via its Makefile
#   • Reloads Dash‑to‑Panel in your running GNOME Shell (no logout required)
#   • Detects your GNOME Shell version and checks out the matching Dash‑to‑Panel release tag
#   • Configures panel thickness, length, position, anchor, visibility & stacking per initial‑setup screenshot
#   • Sets Segoe UI system font
#   • Installs Plank dock and configures it to autostart
#
# Prerequisites:
#   • Ubuntu 24.04+ with GNOME Shell (45, 46, 47, or 48)
#   • No PPAs needed
#
# make-ubuntu-windowsy.sh
#
# Description:
#   Automate turning a fresh Ubuntu 24.10 GNOME desktop into a Windows‑style environment.
#
# Features:
#   • Applies the WhiteSur GTK theme & icon pack
#   • Installs & enables Dash‑to‑Panel (bottom taskbar) via its Makefile
#   • Reloads Dash‑to‑Panel in your running GNOME Shell (no logout required)
#   • Detects your GNOME Shell version and checks out the matching Dash‑to‑Panel release tag
#   • Configures panel thickness, length, position, anchor, visibility & stacking per initial‑setup screenshot
#   • Sets Segoe UI system font
#   • Installs Plank dock and configures it to autostart
#
# Prerequisites:
#   • Ubuntu 24.10 with GNOME Shell (45, 46, 47, or 48)
#   • No PPAs needed
#
# Usage:
#   chmod +x make-ubuntu-windowsy.sh
#   ./make-ubuntu-windowsy.sh
#
# (c) Ralph O'Flinn 2025

set -eo pipefail  # Remove 'u' flag to allow unset variables in conditionals

echo "→ 1. Backing up current GNOME settings…"
dconf dump / > "$HOME/gnome-settings-backup-$(date +%F).dconf" \
  || echo "⚠️ Backup failed—continuing anyway."

echo "→ 2. Updating system & installing prerequisites…"
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  git wget unzip make gettext \
  gnome-tweaks chrome-gnome-shell \
  gnome-shell-extensions gnome-shell-extension-manager \
  ttf-mscorefonts-installer plank

echo "→ 3. Cleaning up previous artifacts…"
rm -rf ~/WhiteSur-gtk-theme ~/.themes/WhiteSur*
rm -rf ~/WhiteSur-icon-theme ~/.icons/WhiteSur*
rm -rf ~/dash-to-panel-src

echo "→ 4. Installing WhiteSur GTK theme…"
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme
bash ~/WhiteSur-gtk-theme/install.sh -d ~/.themes

echo "→ 5. Installing WhiteSur icon pack…"
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme
bash ~/WhiteSur-icon-theme/install.sh -d ~/.icons

echo "→ 6. Installing Dash‑to‑Panel from source…"
git clone https://github.com/home-sweet-gnome/dash-to-panel.git ~/dash-to-panel-src
cd ~/dash-to-panel-src

# Detect GNOME Shell version
GNOME_VER=$(gnome-shell --version | awk '{print $3}')
GNOME_MAJOR=${GNOME_VER%%.*}
echo "   → Detected GNOME Shell $GNOME_VER (major $GNOME_MAJOR)"

# Map major version → release tag
case "$GNOME_MAJOR" in
  45) TAG="v59" ;;
  46) TAG="v61" ;;
  47) TAG="v65" ;;
  48) TAG="v66" ;;
  49) TAG="v66" ;;  # Use latest available for newer versions
  *)  TAG="v66"  ;; # Default to latest for unknown versions
esac

if [[ -n "$TAG" ]]; then
  echo "   → Checking out Dash-to-Panel tag $TAG…"
  git fetch --tags
  git checkout "$TAG" \
    && echo "     ✓ Using tag $TAG" \
    || echo "⚠️ Tag $TAG not found; using default branch."
else
  echo "   → Using latest version for GNOME $GNOME_MAJOR."
fi

echo "   → Running 'make install'…"
make install       # compiles schemas & translations, installs to ~/.local/share/gnome-shell/extensions
cd -

echo "→ 7. Enabling Dash-to-Panel extension…"
# Wait for GNOME Shell to detect the newly installed extension
sleep 3

# Function to check if extension exists
extension_exists() {
  gnome-extensions list | grep -q "dash-to-panel@jderose9.github.com"
}

# Function to check if extension is enabled
extension_enabled() {
  gnome-extensions list --enabled | grep -q "dash-to-panel@jderose9.github.com"
}

# Try multiple approaches to enable the extension
if extension_exists; then
  echo "   → Extension found, attempting to enable..."
  if gnome-extensions enable dash-to-panel@jderose9.github.com; then
    echo "   ✓ Extension enabled successfully"
  else
    echo "⚠️ Direct enable failed, trying reload approach..."
    # Force reload GNOME Shell extension system
    gdbus call --session \
      --dest org.gnome.Shell \
      --object-path /org/gnome/Shell \
      --method org.gnome.Shell.Eval \
      "Main.extensionManager.reloadExtensions()" 2>/dev/null || true
    sleep 2
    gnome-extensions enable dash-to-panel@jderose9.github.com || \
      echo "⚠️ Extension enable failed. You may need to enable it manually after a GNOME Shell restart."
  fi
else
  echo "⚠️ Extension not detected. Forcing extension system reload..."
  # Try to force GNOME Shell to scan for new extensions
  gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
    "Main.extensionManager.reloadExtensions()" 2>/dev/null || true
  sleep 3

  if extension_exists; then
    gnome-extensions enable dash-to-panel@jderose9.github.com || \
      echo "⚠️ Extension found but enable failed. Manual enabling may be required."
  else
    echo "⚠️ Extension still not detected. Please restart GNOME Shell and enable manually."
  fi
fi

echo "→ 8. Reloading Dash-to-Panel in the running GNOME Shell…"
gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.gnome.Shell.Eval \
  "Main.extensionManager.reloadExtension('dash-to-panel@jderose9.github.com')"

echo "→ 9. Applying Windows-style theme, icon pack & Segoe UI font…"
gsettings set org.gnome.desktop.interface gtk-theme  'WhiteSur-light'
gsettings set org.gnome.desktop.interface icon-theme  'WhiteSur'
gsettings set org.gnome.desktop.interface font-name   'Segoe UI 10'

# Apply user-theme extension settings if available
if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
  gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-light'
else
  echo "⚠️ User-theme extension schema not found. Attempting to enable User Themes extension..."
  gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || \
  echo "⚠️ Please enable the User Themes extension manually via GNOME Extensions app."
fi

echo "→ 10. Configuring Dash-to-Panel layout & stacking…"
SCHEMA="org.gnome.shell.extensions.dash-to-panel"

# Check if the schema exists before trying to configure it
if gsettings list-schemas | grep -q "^$SCHEMA$"; then
  echo "   → Schema found, applying configuration..."

  # Position, size & anchor
  gsettings set $SCHEMA panel-position  'BOTTOM'
  gsettings set $SCHEMA panel-thickness 48        # px
  gsettings set $SCHEMA panel-length    100       # % of screen
  gsettings set $SCHEMA anchor          'CENTER'

  # Visibility
  gsettings set $SCHEMA show-applications-button true
  gsettings set $SCHEMA show-activities-button   true
  gsettings set $SCHEMA show-left-box            true
  gsettings set $SCHEMA show-taskbar             true
  gsettings set $SCHEMA show-center-box          true
  gsettings set $SCHEMA show-right-box           true
  gsettings set $SCHEMA show-date-menu           true
  gsettings set $SCHEMA show-system-menu         true
  gsettings set $SCHEMA show-desktop-button      true

  # Stacking: 'START' = left, 'END' = right
  gsettings set $SCHEMA applications-button-box 'START'
  gsettings set $SCHEMA activities-button-box     'START'
  gsettings set $SCHEMA left-box-box              'START'
  gsettings set $SCHEMA taskbar-box               'START'
  gsettings set $SCHEMA center-box-box            'END'
  gsettings set $SCHEMA right-box-box             'END'
  gsettings set $SCHEMA date-menu-box             'END'
  gsettings set $SCHEMA system-menu-box           'END'
  gsettings set $SCHEMA desktop-button-box        'END'

  echo "   ✓ Dash-to-Panel configuration applied"
else
  echo "⚠️ Dash-to-Panel schema not found. Extension may not be properly enabled."
  echo "   Please enable the extension manually and restart GNOME Shell, then run:"
  echo "   dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel-config.dconf"

  # Create a backup configuration file for manual application
  cat > ~/dash-to-panel-config.dconf << 'EOF'
[/]
panel-position='BOTTOM'
panel-thickness=48
panel-length=100
anchor='CENTER'
show-applications-button=true
show-activities-button=true
show-left-box=true
show-taskbar=true
show-center-box=true
show-right-box=true
show-date-menu=true
show-system-menu=true
show-desktop-button=true
applications-button-box='START'
activities-button-box='START'
left-box-box='START'
taskbar-box='START'
center-box-box='END'
right-box-box='END'
date-menu-box='END'
system-menu-box='END'
desktop-button-box='END'
EOF
  echo "   → Configuration saved to ~/dash-to-panel-config.dconf for manual application"
fi

echo "→ 11. Configuring Plank to autostart…"
mkdir -p ~/.config/autostart
cat << EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF

echo "✅ Installation complete!"
echo ""
echo "🎨 Theme and icons applied successfully"
echo "📂 Plank dock configured to autostart"
echo ""

# Check final status and provide guidance
if extension_enabled 2>/dev/null; then
  echo "✅ Dash-to-Panel extension is enabled and configured"
  echo "🎉 Your Windows-style Ubuntu desktop is ready—no logout required!"
else
  echo "⚠️  Manual steps needed:"
  echo "   1. Press Alt+F2, type 'r', and press Enter to restart GNOME Shell"
  echo "   2. Open 'Extensions' app and enable 'Dash to Panel'"
  echo "   3. If configuration is needed, run:"
  echo "      dconf load /org/gnome/shell/extensions/dash-to-panel/ < ~/dash-to-panel-config.dconf"
  echo ""
  echo "🔄 After completing these steps, your Windows-style desktop will be ready!"
fi
