# Enhanced Package Verification System

## Overview

Enhanced the package verification system in `make-ubuntu-windowsy.sh` to automatically detect Ubuntu version, verify package availability, handle version-specific package names, and install missing packages with user confirmation.

## Key Improvements

### 1. Ubuntu Version Detection (`detect_ubuntu_version()`)

- **Purpose**: Detect Ubuntu version and codename for version-specific package handling
- **Detection Method**: Parses `/etc/os-release` for accurate version information
- **Exports**: `UBUNTU_VERSION` and `UBUNTU_CODENAME` environment variables
- **Fallback**: Gracefully handles non-Ubuntu systems

**Example Output:**

```bash
ℹ️  Detected Ubuntu 25.04 (plucky)
```

### 2. Package Availability Verification (`verify_package_availability()`)

- **Multi-Method Verification**:
  1. Local package cache check (`apt-cache show`)
  2. Package search fallback (`apt search`)
  3. Alternative package mapping for known replacements
- **Version-Aware Alternatives**:
  - `chrome-gnome-shell` → `gnome-browser-connector` (Ubuntu 22.04+)
  - `gnome-shell-extension-manager` → graceful degradation
  - `ttf-mscorefonts-installer` → `fonts-liberation` alternatives
- **User Guidance**: Provides links to packages.ubuntu.com for manual verification

### 3. Version-Specific Package Mapping (`get_package_for_ubuntu_version()`)

- **Automatic Package Translation**: Maps deprecated packages to current equivalents
- **Ubuntu Version Awareness**: Different mappings for different Ubuntu versions
- **Future-Proof**: Handles newer Ubuntu versions gracefully

**Key Mappings:**

- Ubuntu 22.04+ : `chrome-gnome-shell` → `gnome-browser-connector`
- All versions: Maintains backward compatibility where possible

### 4. Enhanced Package Installation (`check_required_packages()`)

- **Smart Package Resolution**:
  - Uses version-specific package names
  - Finds suitable alternatives for unavailable packages
  - Separates missing vs unavailable packages
- **User Interaction**:
  - Clear reporting of what will be installed
  - Confirmation prompts for missing packages
  - Option to continue with unavailable packages
  - Graceful error handling with retry options
- **Robust Installation**:
  - Handles partial installation failures
  - Provides clear error messages
  - Offers continuation options

## Installation Flow

### Before Installation

```bash
# Detect system information
detect_ubuntu_version                    # → Ubuntu 25.04 (plucky)
detect_gnome_environment                 # → GNOME Shell detected

# Check package requirements
check_required_packages
```

### Package Resolution Process

```bash
For each required package:
1. Map to version-specific name         # chrome-gnome-shell → gnome-browser-connector
2. Check if already installed           # dpkg -l check
3. Verify availability in repos        # apt-cache show + alternatives
4. Categorize: missing/unavailable      # Separate handling
5. Present options to user              # Clear confirmation prompts
6. Install with error handling          # Robust installation process
```

## User Experience Improvements

### Clear Status Reporting

```bash
ℹ️  Checking for required packages...
ℹ️  Detected Ubuntu 25.04 (plucky)
ℹ️  Updating package cache...
ℹ️  Using alternative package: gnome-browser-connector (instead of chrome-gnome-shell)
ℹ️  Packages to be installed: wget unzip gnome-browser-connector
```

### Unavailable Package Handling

```bash
⚠️  The following packages are not available in repositories:
  - gnome-shell-extension-manager: You can install GNOME extensions manually or use gnome-tweaks
  - old-package: Package not found in repositories
ℹ️  For Ubuntu 25.04 (plucky), check: https://packages.ubuntu.com/search?keywords=old-package
Continue anyway? (y/N):
```

### Installation Confirmation

```bash
Packages to be installed: gnome-browser-connector fonts-liberation
Install missing packages? (y/N): y
ℹ️  Installing packages...
ℹ️  Packages installed successfully
```

## Error Handling & Recovery

### Package Cache Issues

- Updates package cache before verification
- Continues with warnings if cache update fails
- Uses multiple verification methods as fallbacks

### Installation Failures

- Provides detailed error context
- Offers option to continue despite failures
- Suggests manual resolution steps

### Version Compatibility

- Warns about unsupported Ubuntu versions
- Provides package.ubuntu.com links for manual verification
- Graceful degradation for missing packages

## Integration with Script

### Prerequisites Check Enhancement

```bash
check_prerequisites() {
  # Detect Ubuntu version for package compatibility
  detect_ubuntu_version                  # New: Version detection

  # Enhanced GNOME detection (multi-method)
  detect_gnome_environment              # New: Robust detection

  # Version-aware package verification
  check_required_packages               # Enhanced: Smart installation
}
```

### Required Packages Array

```bash
readonly REQUIRED_PACKAGES=(
  "git" "wget" "unzip" "make" "gettext"           # Core tools
  "gnome-tweaks" "chrome-gnome-shell"            # GNOME utilities
  "gnome-shell-extensions" "gnome-shell-extension-manager"  # Extensions
  "ttf-mscorefonts-installer" "plank"            # Themes & dock
)
```

## Benefits

1. **Reliability**: Multiple verification methods prevent false failures
2. **Compatibility**: Handles Ubuntu version differences automatically
3. **User-Friendly**: Clear prompts and error messages
4. **Future-Proof**: Adapts to package name changes across Ubuntu versions
5. **Robust**: Graceful error handling and recovery options
6. **Informative**: Detailed logging and status reporting

## Supported Ubuntu Versions

- **Ubuntu 20.04 LTS (Focal)**: Full compatibility with original package names
- **Ubuntu 22.04 LTS (Jammy)**: Automatic chrome-gnome-shell → gnome-browser-connector mapping
- **Ubuntu 24.04 LTS (Noble)**: Enhanced package support
- **Ubuntu 25.04 (Plucky)**: Latest package mappings and compatibility
- **Future Versions**: Graceful handling with latest available packages

This enhancement ensures reliable package installation across all supported Ubuntu versions while providing clear feedback and robust error handling.
