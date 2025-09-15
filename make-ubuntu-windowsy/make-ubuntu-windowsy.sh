#!/usr/bin/env bash
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

set -euo pipefail

echo "→ 1. Backing up current GNOME settings…"
dconf dump / > ~/gnome-settings-backup-$(date +%F).dconf \
  || echo "⚠️ Backup failed—continuing anyway."

echo "→ 2. Updating system & installing prerequisites…"
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  git wget unzip make gettext \
  gnome-tweaks chrome-gnome-shell \
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
  *)  TAG=""  ;;
esac

if [[ -n "$TAG" ]]; then
  echo "   → Checking out Dash-to-Panel tag $TAG…"
  git fetch --tags
  git checkout "$TAG" \
    && echo "     ✓ Using tag $TAG" \
    || echo "⚠️ Tag $TAG not found; using default branch."
else
  echo "   → No known tag for GNOME $GNOME_MAJOR; staying on default branch."
fi

echo "   → Running 'make install'…"
make install       # compiles schemas & translations, installs to ~/.local/share/gnome-shell/extensions
cd -

echo "→ 7. Enabling Dash-to-Panel extension…"
if ! gnome-extensions enable dash-to-panel@jderose9.github.com; then
  echo "⚠️ Could not enable extension; ensure GNOME Shell is running."
fi

echo "→ 8. Reloading Dash-to-Panel in the running GNOME Shell…"
gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.gnome.Shell.Eval \
  "Main.extensionManager.reloadExtension('dash-to-panel@jderose9.github.com')"

echo "→ 9. Applying Windows-style theme, icon pack & Segoe UI font…"
gsettings set org.gnome.desktop.interface gtk-theme  'WhiteSur-light'
gsettings set org.gnome.shell.extensions.user-theme    name     'WhiteSur-light'
gsettings set org.gnome.desktop.interface icon-theme  'WhiteSur'
gsettings set org.gnome.desktop.interface font-name   'Segoe UI 10'

echo "→ 10. Configuring Dash-to-Panel layout & stacking…"
SCHEMA="org.gnome.shell.extensions.dash-to-panel"

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

echo "→ 11. Configuring Plank to autostart…"
mkdir -p ~/.config/autostart
cat << EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF

echo "✅ All done! Your Windows-style Ubuntu desktop is ready—no logout required."
