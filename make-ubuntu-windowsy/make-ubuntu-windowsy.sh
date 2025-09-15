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
detect_ubuntu_version() {
  log_debug "Detecting Ubuntu version..."

  if [[ -f /etc/os-release ]]; then
    # Extract Ubuntu version information
    local ubuntu_version
    local version_codename
    local version_id

    # Source the os-release file to get version info
    # shellcheck source=/etc/os-release
    source /etc/os-release

    ubuntu_version="$NAME"
    # shellcheck disable=SC2153  # VERSION_CODENAME and VERSION_ID are from sourced file
    version_codename="$VERSION_CODENAME"
    # shellcheck disable=SC2153
    version_id="$VERSION_ID"

    if [[ "$ubuntu_version" =~ Ubuntu ]]; then
      export UBUNTU_VERSION="$version_id"
      export UBUNTU_CODENAME="$version_codename"
      log_info "Detected $ubuntu_version ($version_codename)"
      log_debug "Ubuntu version: $version_id, codename: $version_codename"

        # Check minimum Ubuntu version requirement
        if ! check_ubuntu_compatibility "$version_id"; then
          log_error "This script requires Ubuntu 24.04 or later"
          log_error "Current version: $version_id ($version_codename)"
          return 1
        fi

      return 0
    else
      log_warn "Not running on Ubuntu (detected: $ubuntu_version)"
      log_warn "Package availability checks may be unreliable"
      export UBUNTU_VERSION="unknown"
      export UBUNTU_CODENAME="unknown"
      return 1
    fi
  else
    log_error "Cannot detect Ubuntu version (/etc/os-release not found)"
    export UBUNTU_VERSION="unknown"
    export UBUNTU_CODENAME="unknown"
    return 1
  fi
}

# Check if Ubuntu version meets minimum requirements
check_ubuntu_compatibility() {
  local version="$1"

  # Handle unknown version
  if [[ "$version" == "unknown" || -z "$version" ]]; then
    log_warn "Cannot verify Ubuntu version compatibility"
    return 0  # Allow to proceed with warning
  fi

  # Extract major and minor version numbers
  if [[ "$version" =~ ^([0-9]+)\.([0-9]+) ]]; then
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"

    log_debug "Checking Ubuntu $major.$minor compatibility"

    # Check if version is 24.04 or later
    if [[ "$major" -gt 24 ]] || [[ "$major" -eq 24 && "$minor" -ge 4 ]]; then
      log_debug "Ubuntu $version meets minimum requirement (24.04+)"
      return 0
    else
      log_debug "Ubuntu $version below minimum requirement (24.04+)"
      return 1
    fi
  else
    log_warn "Cannot parse Ubuntu version format: $version"
    return 0  # Allow to proceed with warning
  fi
}

verify_package_availability() {
  local package="$1"
  local ubuntu_version="${UBUNTU_VERSION:-unknown}"

  log_debug "Verifying availability of package: $package"

  # Method 1: Check local package cache
  if apt-cache show "$package" >/dev/null 2>&1; then
    log_debug "Package $package found in local cache"
    echo "$package"  # Return the original package name
    return 0
  fi

  # Method 2: Try apt search as fallback
  if apt search "^${package}$" 2>/dev/null | grep -q "^${package}/"; then
    log_debug "Package $package found via apt search"
    echo "$package"  # Return the original package name
    return 0
  fi

  # Method 3: Check if it's a virtual package or has alternatives
  local alternatives=()
  case "$package" in
    "chrome-gnome-shell")
      alternatives=("gnome-browser-connector")
      log_debug "Checking alternatives for chrome-gnome-shell: ${alternatives[*]}"
      ;;
    "gnome-shell-extension-manager")
      alternatives=("gnome-shell-extensions")
      log_debug "Checking alternatives for gnome-shell-extension-manager: ${alternatives[*]}"
      ;;
    "ttf-mscorefonts-installer")
      alternatives=("fonts-liberation" "fonts-liberation2")
      log_debug "Checking alternatives for ttf-mscorefonts-installer: ${alternatives[*]}"
      ;;
  esac

  # Check alternatives
  for alt in "${alternatives[@]}"; do
    if apt-cache show "$alt" >/dev/null 2>&1; then
      log_info "Alternative package found: $alt (for $package)"
      echo "$alt"  # Return the alternative package name
      return 0
    fi
  done

  log_warn "Package $package not available in repositories"
  if [[ "$ubuntu_version" != "unknown" ]]; then
    log_info "For Ubuntu $ubuntu_version ($UBUNTU_CODENAME), check: https://packages.ubuntu.com/search?keywords=$package"
  fi

  return 1
}

get_package_for_ubuntu_version() {
  local package="$1"
  local ubuntu_version="${UBUNTU_VERSION:-unknown}"

  # Handle packages that have different names across Ubuntu versions
  case "$package" in
    "chrome-gnome-shell")
      # chrome-gnome-shell was replaced by gnome-browser-connector in Ubuntu 22.04+
      if [[ "$ubuntu_version" =~ ^(22|23|24|25)\. ]]; then
        if verify_package_availability "gnome-browser-connector" >/dev/null; then
          echo "gnome-browser-connector"
          return 0
        fi
      fi
      echo "$package"
      ;;
    "gnome-shell-extension-manager")
      # Check if available, otherwise suggest gnome-tweaks
      if verify_package_availability "$package" >/dev/null; then
        echo "$package"
      else
        echo ""  # Will be handled as unavailable
      fi
      ;;
    *)
      echo "$package"
      ;;
  esac

  return 0
}

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

  # Detect Ubuntu version for better package availability checking
  detect_ubuntu_version

  local missing_packages=()
  local unavailable_packages=()
  local package_substitutions=()

  # Update package cache first
  log_info "Updating package cache..."
  if ! sudo apt update >/dev/null 2>&1; then
    log_warn "Failed to update package cache, continuing anyway..."
  fi

  for package in "${REQUIRED_PACKAGES[@]}"; do
    # Get the appropriate package name for this Ubuntu version
    local target_package
    target_package=$(get_package_for_ubuntu_version "$package")

    if [[ -z "$target_package" ]]; then
      log_debug "No suitable package found for $package"
      unavailable_packages+=("$package")
      continue
    fi

    if dpkg -l "$target_package" >/dev/null 2>&1; then
      log_debug "Package installed: $target_package"
    else
      log_debug "Package not installed: $target_package"

      # Verify package availability and get alternatives if needed
      if alternative=$(verify_package_availability "$target_package"); then
        if [[ "$alternative" != "$target_package" ]]; then
          # Alternative package found
          log_info "Using alternative package: $alternative (instead of $target_package)"
          package_substitutions+=("$alternative")
        else
          # Original package is available
          missing_packages+=("$target_package")
        fi
      else
        # Package not available in repositories
        unavailable_packages+=("$target_package")
      fi
    fi
  done

  # Handle unavailable packages
  if [[ ${#unavailable_packages[@]} -gt 0 ]]; then
    log_warn "The following packages are not available in repositories:"
    for pkg in "${unavailable_packages[@]}"; do
      case "$pkg" in
        "chrome-gnome-shell")
          log_warn "  - $pkg: Try installing 'gnome-browser-connector' instead"
          log_info "    Note: chrome-gnome-shell was replaced by gnome-browser-connector in newer Ubuntu versions"
          ;;
        "gnome-shell-extension-manager")
          log_warn "  - $pkg: You can install GNOME extensions manually or use gnome-tweaks"
          ;;
        "ttf-mscorefonts-installer")
          log_warn "  - $pkg: Consider installing 'fonts-liberation' or 'fonts-liberation2' for similar fonts"
          ;;
        *)
          log_warn "  - $pkg: Package not found in repositories"
          ;;
      esac
    done

    log_info "You can continue without these packages, but some features may not work optimally."
    read -rp "Continue anyway? (y/N): " -n 1 continue_anyway
    echo
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
      log_error "Installation cancelled by user."
      return 1
    fi
  fi

  # Combine missing packages and substitutions
  local packages_to_install=("${missing_packages[@]}" "${package_substitutions[@]}")

  if [[ ${#packages_to_install[@]} -gt 0 ]]; then
    log_info "Packages to be installed: ${packages_to_install[*]}"

    # Ask for confirmation
    read -rp "Install missing packages? (y/N): " -n 1 install_packages
    echo
    if [[ ! "$install_packages" =~ ^[Yy]$ ]]; then
      log_error "Cannot proceed without required packages."
      return 1
    fi

    # Install missing packages
    log_info "Installing packages..."
    if sudo apt install -y "${packages_to_install[@]}"; then
      log_info "Packages installed successfully"
    else
      log_error "Some packages failed to install. Check the output above for details."
      log_info "You may need to resolve package conflicts or missing dependencies manually."

      read -rp "Continue with installation anyway? (y/N): " -n 1 continue_anyway
      echo
      if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        return 1
      fi
    fi
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

  # Detect Ubuntu version for package compatibility
  if detect_ubuntu_version; then
    log_info "Running on Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"
  else
    log_warn "Not running on Ubuntu or version detection failed"
    log_warn "Package installation may encounter issues"
  fi

  # Check GNOME environment using enhanced detection
  if ! detect_gnome_environment; then
    log_warn "GNOME desktop not detected. This script is designed for GNOME."
    read -rp "Continue anyway? (y/N): " -n 1 continue_anyway
    echo
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
      log_info "Aborted by user."
        return 1
    fi
  fi

  # Check internet connectivity
  if ! ping -c 1 8.8.8.8 &>/dev/null; then
    log_error "No internet connection detected. This script requires internet access."
      return 1
  fi

  # Check for required commands (GNOME components, etc.)
  if ! check_required_commands; then
    log_error "Missing required system commands. Cannot proceed."
      return 1
  fi

  # Check and install required packages
  if ! check_required_packages; then
    log_error "Package verification failed. Cannot proceed."
      return 1
  fi

  log_info "Prerequisites check passed"
}

# Main execution
main() {
  log_info "Starting Ubuntu Windowsy transformation..."
  log_debug "Debug mode enabled"

  log_info "→ 0. Checking prerequisites…"
    if ! check_prerequisites; then
      log_error "Prerequisites check failed. Cannot proceed."
      exit 1
    fi

  log_info "→ 1. Backing up current GNOME settings…"
  dconf dump / > "$HOME/gnome-settings-backup-$(date +%F).dconf" \
    || log_warn "Backup failed—continuing anyway."

  log_info "→ 2. Cleaning up previous artifacts…"
  cleanup_previous_artifacts

  log_info "→ 3. Installing WhiteSur GTK theme…"
    if ! install_whitesur_theme; then
      log_error "WhiteSur theme installation failed. Cannot proceed."
      exit 1
    fi

  log_info "→ 4. Installing WhiteSur icon pack…"
    if ! install_whitesur_icons; then
      log_error "WhiteSur icons installation failed. Cannot proceed."
      exit 1
    fi

  log_info "→ 5. Installing Dash‑to‑Panel from source…"
    if ! install_dash_to_panel; then
      log_error "Dash-to-Panel installation failed. Cannot proceed."
      exit 1
    fi

  log_info "→ 6. Enabling Dash-to-Panel extension…"
  enable_dash_to_panel

  log_info "→ 7. Applying theme and icons…"
  apply_theme_settings

  log_info "→ 8. Configuring system font…"
  configure_system_font

  log_info "→ 9. Setting up Plank dock…"
  setup_plank

  log_info "✅ Installation complete!"
  display_completion_message
}

# Utility functions
cleanup_previous_artifacts() {
  log_debug "Cleaning up previous artifacts…"
  rm -rf ~/WhiteSur-gtk-theme ~/.themes/WhiteSur*
  rm -rf ~/WhiteSur-icon-theme ~/.icons/WhiteSur*
  rm -rf ~/dash-to-panel-src
}

install_whitesur_theme() {
  log_debug "Installing WhiteSur GTK theme…"
  if ! git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ~/WhiteSur-gtk-theme; then
    log_error "Failed to clone WhiteSur GTK theme repository"
    return 1
  fi

  if ! bash ~/WhiteSur-gtk-theme/install.sh -d ~/.themes; then
    log_error "Failed to install WhiteSur GTK theme"
    return 1
  fi
}

install_whitesur_icons() {
  log_debug "Installing WhiteSur icon pack…"
  if ! git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ~/WhiteSur-icon-theme; then
    log_error "Failed to clone WhiteSur icon theme repository"
    return 1
  fi

  if ! bash ~/WhiteSur-icon-theme/install.sh -d ~/.icons; then
    log_error "Failed to install WhiteSur icon theme"
    return 1
  fi
}

install_dash_to_panel() {
  # Verify GNOME environment and version
  if ! detect_gnome_environment; then
    log_error "GNOME environment not detected. This script requires GNOME Shell."
    return 1
  fi

  if ! detect_gnome_version; then
    log_error "Failed to detect GNOME Shell version"
    return 1
  fi

  # Get appropriate Dash-to-Panel version
  if ! TAG=$(get_dash_to_panel_version); then
    log_error "Failed to determine Dash-to-Panel version"
    return 1
  fi

  log_info "Installing Dash-to-Panel $TAG for GNOME Shell $GNOME_VER"

  git clone https://github.com/home-sweet-gnome/dash-to-panel.git ~/dash-to-panel-src
  cd ~/dash-to-panel-src

  if [[ -n "$TAG" ]]; then
    log_debug "Checking out Dash-to-Panel tag $TAG…"
    git fetch --tags
    if git checkout "$TAG"; then
      log_debug "Using tag $TAG"
    else
      log_warn "Tag $TAG not found; using default branch."
    fi
  else
    log_debug "Using latest version for GNOME $GNOME_MAJOR."
  fi

  log_debug "Running 'make install'…"
  make install       # compiles schemas & translations, installs to ~/.local/share/gnome-shell/extensions
  cd -
}

enable_dash_to_panel() {
  # Wait for GNOME Shell to detect the newly installed extension
  sleep "$EXTENSION_WAIT_TIME"

  # Try multiple approaches to enable the extension
  if extension_exists; then
    log_debug "Extension found, attempting to enable..."
    if gnome-extensions enable dash-to-panel@jderose9.github.com; then
      log_info "Extension enabled successfully"
    else
      log_warn "Direct enable failed, trying reload approach..."
      # Force reload GNOME Shell extension system
      gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell \
        --method org.gnome.Shell.Eval \
        "Main.extensionManager.reloadExtensions()" 2>/dev/null || true
      sleep "$RETRY_WAIT_TIME"
      gnome-extensions enable dash-to-panel@jderose9.github.com || \
        log_warn "Extension enable failed. You may need to enable it manually after a GNOME Shell restart."
    fi
  else
    log_warn "Extension not detected. Forcing extension system reload..."
    # Try to force GNOME Shell to scan for new extensions
    gdbus call --session \
      --dest org.gnome.Shell \
      --object-path /org/gnome/Shell \
      --method org.gnome.Shell.Eval \
      "Main.extensionManager.reloadExtensions()" 2>/dev/null || true
    sleep "$EXTENSION_WAIT_TIME"

    if extension_exists; then
      gnome-extensions enable dash-to-panel@jderose9.github.com || \
        log_warn "Extension found but enable failed. Manual enabling may be required."
    else
      log_warn "Extension still not detected. Please restart GNOME Shell and enable manually."
    fi
  fi

  # Reload the extension in the running GNOME Shell
  log_debug "Reloading Dash-to-Panel in the running GNOME Shell…"
  gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
    "Main.extensionManager.reloadExtension('dash-to-panel@jderose9.github.com')"
}

# Function to check if extension exists
extension_exists() {
  gnome-extensions list | grep -q "dash-to-panel@jderose9.github.com"
}

# Function to check if extension is enabled
extension_enabled() {
  gnome-extensions list --enabled | grep -q "dash-to-panel@jderose9.github.com"
}

apply_theme_settings() {
  log_debug "Applying Windows-style theme, icon pack & Segoe UI font…"
  gsettings set org.gnome.desktop.interface gtk-theme  'WhiteSur-light'
  gsettings set org.gnome.desktop.interface icon-theme  'WhiteSur'
  gsettings set org.gnome.desktop.interface font-name   'Segoe UI 10'

  # Apply user-theme extension settings if available
  if gsettings list-schemas | grep -q "org.gnome.shell.extensions.user-theme"; then
    gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-light'
  else
    log_warn "User-theme extension schema not found. Attempting to enable User Themes extension..."
    gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || \
    log_warn "Please enable the User Themes extension manually via GNOME Extensions app."
  fi

  configure_dash_to_panel
}

configure_dash_to_panel() {
  log_debug "Configuring Dash-to-Panel layout & stacking…"
  local SCHEMA="org.gnome.shell.extensions.dash-to-panel"

  # Check if the schema exists before trying to configure it
  if gsettings list-schemas | grep -q "^$SCHEMA$"; then
    log_debug "Schema found, applying configuration..."

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

    log_info "Dash-to-Panel configuration applied"
  else
    log_warn "Dash-to-Panel schema not found. Extension may not be properly enabled."
    log_info "Please enable the extension manually and restart GNOME Shell, then run:"
    log_info "dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel-config.dconf"

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
    log_info "Configuration saved to ~/dash-to-panel-config.dconf for manual application"
  fi
}

configure_system_font() {
  # Font is already configured in apply_theme_settings
  log_debug "System font configuration completed in theme settings"
}

setup_plank() {
  log_debug "Configuring Plank to autostart…"
  mkdir -p ~/.config/autostart
  cat << EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF
}

display_completion_message() {
  echo ""
  log_info "🎨 Theme and icons applied successfully"
  log_info "📂 Plank dock configured to autostart"
  echo ""

  # Check final status and provide guidance
  if extension_enabled 2>/dev/null; then
    log_info "✅ Dash-to-Panel extension is enabled and configured"
    log_info "🎉 Your Windows-style Ubuntu desktop is ready—no logout required!"
  else
    log_warn "Manual steps needed:"
    echo "   1. Press Alt+F2, type 'r', and press Enter to restart GNOME Shell"
    echo "   2. Open 'Extensions' app and enable 'Dash to Panel'"
    echo "   3. If configuration is needed, run:"
    echo "      dconf load /org/gnome/shell/extensions/dash-to-panel/ < ~/dash-to-panel-config.dconf"
    echo ""
    log_info "🔄 After completing these steps, your Windows-style desktop will be ready!"
  fi
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
