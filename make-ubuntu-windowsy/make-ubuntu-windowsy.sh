#!/usr/bin/env bash
#
# make-ubuntu-windowsy.sh
#
# Description:
#   Automate turning a fresh Ubuntu GNOME desktop into a Windows‑style environment.
#   Compatible with Ubuntu 24.04, 24.10, and 25.04.
#
# Features:
#   • Applies the WhiteSur GTK theme & icon pack
#   • Installs & enables Dash‑to‑Panel (bottom taskbar) via its Makefile
#   • Reloads Dash‑to‑Panel in your running GNOME Shell (no logout required)
#   • Detects your GNOME Shell version and checks out the matching Dash‑to‑Panel release tag
#   • Supports GNOME 45-49+ with latest maintenance releases (updated Jan 2025)
#   • Configures panel thickness, length, position, anchor, visibility & stacking
#   • Sets Segoe UI system font
#   • Installs Plank dock and configures it to autostart
#
# Prerequisites:
#   • Ubuntu 24.04+ with GNOME Shell (45, 46, 47, 48, or 49+)
#   • No PPAs needed
#
# Usage:
#   chmod +x make-ubuntu-windowsy.sh
#   ./make-ubuntu-windowsy.sh
#
# (c) Ralph O'Flinn 2025

set -eo pipefail  # Remove 'u' flag to allow unset variables in conditionals

# Configuration constants
readonly EXTENSION_WAIT_TIME=${EXTENSION_WAIT_TIME:-3}
readonly RETRY_WAIT_TIME=${RETRY_WAIT_TIME:-2}
readonly BACKUP_PREFIX="gnome-settings-backup"  # Used in backup functions (TODO: implement)
readonly DEBUG=${DEBUG:-false}

# Required packages for the script to function
readonly REQUIRED_PACKAGES=(
  "git" "wget" "unzip" "make" "gettext"
  "gnome-tweaks" "chrome-gnome-shell"
  "gnome-shell-extensions" "gnome-shell-extension-manager"
  "ttf-mscorefonts-installer" "plank"
)

# Required commands that must be available
readonly REQUIRED_COMMANDS=(
  "gnome-shell" "gnome-extensions" "gsettings" "gdbus" "dconf"
  "ping" "grep" "awk" "apt" "sudo"
)

# Logging functions
log_debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "🔍 DEBUG: $*" >&2
  fi
}

log_info() {
  echo "ℹ️  $*"
}

log_warn() {
  echo "⚠️  $*" >&2
}

log_error() {
  echo "❌ $*" >&2
}

# Signal handling for cleanup
cleanup_on_exit() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script exited with error code $exit_code"
    log_info "Consider checking the logs above for details"
  fi
}

trap cleanup_on_exit EXIT

# Package verification functions
check_required_commands() {
  log_info "Checking required commands..."
  local missing_commands=()

  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_commands+=("$cmd")
      log_warn "Missing command: $cmd"
    else
      log_debug "Found command: $cmd"
    fi
  done

  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing_commands[*]}"
    log_error "This system appears to be missing GNOME desktop components."
    log_info "Please ensure you're running this on a GNOME desktop environment."
    return 1
  fi

  log_info "All required commands are available"
  return 0
}

check_required_packages() {
  log_info "Checking for required packages..."
  local missing_packages=()

  # Update package cache first
  log_info "Updating package cache..."
  if ! sudo apt update >/dev/null 2>&1; then
    log_warn "Failed to update package cache, continuing anyway..."
  fi

  for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l "$package" >/dev/null 2>&1; then
      if apt-cache show "$package" >/dev/null 2>&1; then
        missing_packages+=("$package")
        log_debug "Package not installed: $package"
      else
        log_warn "Package not available in repositories: $package"
      fi
    else
      log_debug "Package installed: $package"
    fi
  done

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    log_info "Missing packages will be installed: ${missing_packages[*]}"

    # Ask for confirmation
    read -rp "Install missing packages? (y/N): " -n 1 install_packages
    echo
    if [[ ! "$install_packages" =~ ^[Yy]$ ]]; then
      log_error "Cannot proceed without required packages."
      return 1
    fi

    # Install missing packages
    log_info "Installing missing packages..."
    if ! sudo apt install -y "${missing_packages[@]}"; then
      log_error "Failed to install required packages."
      return 1
    fi

    log_info "Required packages installed successfully"
  else
    log_info "All required packages are already installed"
  fi

  return 0
}

# Enhanced GNOME detection functions
# These functions provide robust cross-version GNOME detection
# supporting Ubuntu variants and different desktop configurations

detect_gnome_environment() {
  log_info "Detecting GNOME environment..."

  # Method 1: Check if GNOME Shell process is running
  if pgrep -x "gnome-shell" >/dev/null 2>&1; then
    log_debug "GNOME Shell process detected"
    return 0
  fi

  # Method 2: Check XDG_CURRENT_DESKTOP (multiple possible values)
  case "${XDG_CURRENT_DESKTOP:-}" in
    *GNOME*|*Unity*|*ubuntu*)
      log_debug "GNOME-based desktop detected via XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
      return 0
      ;;
  esac

  # Method 3: Check DESKTOP_SESSION
  case "${DESKTOP_SESSION:-}" in
    gnome*|ubuntu*|unity*)
      log_debug "GNOME-based session detected via DESKTOP_SESSION: $DESKTOP_SESSION"
      return 0
      ;;
  esac

  # Method 4: Check if GNOME Shell binary exists and is executable
  if command -v gnome-shell >/dev/null 2>&1; then
    log_debug "GNOME Shell command available"
    return 0
  fi

  log_debug "GNOME environment not detected"
  return 1
}

detect_gnome_version() {
  log_info "Detecting GNOME Shell version..."

  # Ensure gnome-shell command is available
  if ! command -v gnome-shell >/dev/null 2>&1; then
    log_error "gnome-shell command not found"
    return 1
  fi

  # Get version string
  local version_output
  if ! version_output=$(gnome-shell --version 2>/dev/null); then
    log_error "Failed to get GNOME Shell version"
    return 1
  fi

  log_debug "Raw version output: '$version_output'"

  # Parse version with multiple fallback methods
  local version=""
  local major_version=""

  # Method 1: Standard "GNOME Shell X.Y.Z" format
  if [[ "$version_output" =~ GNOME\ Shell\ ([0-9]+)\.([0-9]+)([\.0-9]*) ]]; then
    version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    major_version="${BASH_REMATCH[1]}"
    log_debug "Parsed version using method 1: $version (major: $major_version)"

  # Method 2: Just numbers after "GNOME Shell"
  elif [[ "$version_output" =~ GNOME\ Shell\ ([0-9]+) ]]; then
    major_version="${BASH_REMATCH[1]}"
    version="$major_version"
    log_debug "Parsed version using method 2: $version (major: $major_version)"

  # Method 3: Extract any version-like pattern
  elif [[ "$version_output" =~ ([0-9]+)\.([0-9]+) ]]; then
    version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    major_version="${BASH_REMATCH[1]}"
    log_debug "Parsed version using method 3: $version (major: $major_version)"

  # Method 4: Extract just the first number
  elif [[ "$version_output" =~ ([0-9]+) ]]; then
    major_version="${BASH_REMATCH[1]}"
    version="$major_version"
    log_debug "Parsed version using method 4: $version (major: $major_version)"
  else
    log_error "Could not parse GNOME Shell version from: '$version_output'"
    return 1
  fi

  # Validate major version is numeric and in reasonable range
  if ! [[ "$major_version" =~ ^[0-9]+$ ]] || [[ "$major_version" -lt 40 ]] || [[ "$major_version" -gt 60 ]]; then
    log_error "Invalid GNOME Shell major version: '$major_version'"
    return 1
  fi

  # Check if version is supported
  if [[ "$major_version" -lt 45 ]]; then
    log_warn "GNOME Shell $major_version is below minimum supported version (45)"
    log_warn "The script may not work correctly with older GNOME versions"
  elif [[ "$major_version" -gt 49 ]]; then
    log_info "GNOME Shell $major_version is newer than tested versions"
    log_info "Using latest available Dash-to-Panel version"
  fi

  # Export for use by other functions
  export GNOME_VER="$version"
  export GNOME_MAJOR="$major_version"

  log_info "Detected GNOME Shell $version (major version: $major_version)"
  return 0
}

get_dash_to_panel_version() {
  local gnome_major="${GNOME_MAJOR:-}"

  if [[ -z "$gnome_major" ]]; then
    log_error "GNOME major version not detected. Run detect_gnome_version first."
    return 1
  fi

  log_debug "Getting Dash-to-Panel version for GNOME $gnome_major"

  # Version mapping based on GNOME Shell version
  # Updated to latest maintenance releases as of January 2025
  case "$gnome_major" in
    45)
      echo "v60"
      log_debug "GNOME 45 -> Dash-to-Panel v60"
      ;;
    46)
      echo "v62"
      log_debug "GNOME 46 -> Dash-to-Panel v62"
      ;;
    47)
      echo "v65"
      log_debug "GNOME 47 -> Dash-to-Panel v65"
      ;;
    48)
      echo "v68"
      log_debug "GNOME 48 -> Dash-to-Panel v68"
      ;;
    49|5[0-9]|6[0-9])
      # GNOME 49+ uses latest available version
      echo "v70"
      log_debug "GNOME $gnome_major -> Dash-to-Panel v70 (latest)"
      ;;
    *)
      log_error "Unsupported GNOME version: $gnome_major"
      log_error "Supported versions: 45, 46, 47, 48, 49+"
      return 1
      ;;
  esac

  return 0
}

install_packages() {
  log_info "Installing/updating system packages..."

  # Upgrade system (optional, but recommended)
  if ! sudo apt upgrade -y; then
    log_warn "System upgrade failed, continuing anyway..."
  fi

  # Ensure all packages are up to date
  if ! sudo apt install -y "${REQUIRED_PACKAGES[@]}"; then
    log_error "Failed to install/update packages. Check package availability."
    return 1
  fi

  log_info "Package installation/update completed"
  return 0
}

# Validation functions
check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check if running on Ubuntu
  if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    log_warn "This script is designed for Ubuntu. Proceeding anyway..."
  fi

  # Check if GNOME is running
  if [[ "${XDG_CURRENT_DESKTOP:-}" != *"GNOME"* ]]; then
    log_warn "GNOME desktop not detected. This script is designed for GNOME."
    read -rp "Continue anyway? (y/N): " -n 1 continue_anyway
    echo
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
      log_info "Aborted by user."
      exit 1
    fi
  fi

  # Check internet connectivity
  if ! ping -c 1 8.8.8.8 &>/dev/null; then
    log_error "No internet connection detected. This script requires internet access."
    exit 1
  fi

  # Check for required commands (GNOME components, etc.)
  if ! check_required_commands; then
    log_error "Missing required system commands. Cannot proceed."
    exit 1
  fi

  # Check and install required packages
  if ! check_required_packages; then
    log_error "Package verification failed. Cannot proceed."
    exit 1
  fi

  log_info "Prerequisites check passed"
}

# Main execution
main() {
  log_info "Starting Ubuntu Windowsy transformation..."
  log_debug "Debug mode enabled"

  check_prerequisites
  cleanup_previous_artifacts
  install_whitesur_theme
  install_whitesur_icons
  # Continue with remaining functions...
}

echo "→ 0. Checking prerequisites…"
check_prerequisites

echo "→ 1. Backing up current GNOME settings…"
dconf dump / > "$HOME/gnome-settings-backup-$(date +%F).dconf" \
  || echo "⚠️ Backup failed—continuing anyway."

# Utility functions
cleanup_previous_artifacts() {
  echo "→ 2. Cleaning up previous artifacts…"
  rm -rf ~/WhiteSur-gtk-theme ~/.themes/WhiteSur*
  rm -rf ~/WhiteSur-icon-theme ~/.icons/WhiteSur*
  rm -rf ~/dash-to-panel-src
}

install_whitesur_theme() {
  echo "→ 3. Installing WhiteSur GTK theme…"
  if ! git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme; then
    echo "❌ Failed to clone WhiteSur GTK theme repository"
    return 1
  fi

  if ! bash ~/WhiteSur-gtk-theme/install.sh -d ~/.themes; then
    echo "❌ Failed to install WhiteSur GTK theme"
    return 1
  fi
}

install_whitesur_icons() {
  echo "→ 4. Installing WhiteSur icon pack…"
  if ! git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme; then
    echo "❌ Failed to clone WhiteSur icon theme repository"
    return 1
  fi

  if ! bash ~/WhiteSur-icon-theme/install.sh -d ~/.icons; then
    echo "❌ Failed to install WhiteSur icon theme"
    return 1
  fi
}

cleanup_previous_artifacts
install_whitesur_theme
install_whitesur_icons

echo "→ 5. Installing Dash‑to‑Panel from source…"

# Verify GNOME environment and version
if ! detect_gnome_environment; then
  log_error "GNOME environment not detected. This script requires GNOME Shell."
  exit 1
fi

if ! detect_gnome_version; then
  log_error "Failed to detect GNOME Shell version"
  exit 1
fi

# Get appropriate Dash-to-Panel version
if ! TAG=$(get_dash_to_panel_version); then
  log_error "Failed to determine Dash-to-Panel version"
  exit 1
fi

log_info "Installing Dash-to-Panel $TAG for GNOME Shell $GNOME_VER"

git clone https://github.com/home-sweet-gnome/dash-to-panel.git ~/dash-to-panel-src
cd ~/dash-to-panel-src

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

echo "→ 6. Enabling Dash-to-Panel extension…"
# Wait for GNOME Shell to detect the newly installed extension
sleep "$EXTENSION_WAIT_TIME"

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
    sleep "$RETRY_WAIT_TIME"
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
  sleep "$EXTENSION_WAIT_TIME"

  if extension_exists; then
    gnome-extensions enable dash-to-panel@jderose9.github.com || \
      echo "⚠️ Extension found but enable failed. Manual enabling may be required."
  else
    echo "⚠️ Extension still not detected. Please restart GNOME Shell and enable manually."
  fi
fi

echo "→ 7. Reloading Dash-to-Panel in the running GNOME Shell…"
gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.gnome.Shell.Eval \
  "Main.extensionManager.reloadExtension('dash-to-panel@jderose9.github.com')"

echo "→ 8. Applying Windows-style theme, icon pack & Segoe UI font…"
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

echo "→ 9. Configuring Dash-to-Panel layout & stacking…"
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

echo "→ 10. Configuring Plank to autostart…"
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
