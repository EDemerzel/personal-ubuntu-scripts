#!/usr/bin/env bash
set -euo pipefail

# new-script.sh - Create a new script folder from template
#
# Usage: ./bin/new-script.sh [--powershell|--python] <script-name> [description]
#
# Creates a new script directory with boilerplate files from the template.
# Supports Bash, PowerShell, and Python script creation.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
BASH_TEMPLATE_DIR="$ROOT_DIR/templates/script-template"
POWERSHELL_TEMPLATE_DIR="$ROOT_DIR/templates/powershell-template"
PYTHON_TEMPLATE_DIR="$ROOT_DIR/templates/python-template"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debug mode
DEBUG=${DEBUG:-false}

# Logging functions
log_debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "${BLUE}🔍 DEBUG: $*${NC}" >&2
  fi
}

log_info() {
  echo -e "${GREEN}ℹ️  $*${NC}"
}

log_warn() {
  echo -e "${YELLOW}⚠️  $*${NC}" >&2
}

log_error() {
  echo -e "${RED}❌ $*${NC}" >&2
}

# Legacy functions for backward compatibility
error() {
  log_error "$*"
  exit 1
}

info() {
  log_info "$*"
}

warn() {
  log_warn "$*"
}

usage() {
  cat << EOF
Usage: $0 [--powershell|--python] <script-name> [description]

Creates a new script directory with boilerplate files.

Options:
  --powershell  Create a PowerShell script instead of a Bash script
  --python      Create a Python script instead of a Bash script

Arguments:
  script-name   Name of the script (will be used for directory and main script file)
  description   Optional description of what the script does

Examples:
  $0 backup-dotfiles "Backup user dotfiles to cloud storage"
  $0 setup-dev-env "Configure development environment"
  $0 --powershell get-system-info "Get detailed system information"
  $0 --python data-processor "Process and analyze data files"

The script will:
1. Create a new directory named <script-name>
2. Copy template files (README.md, LICENSE, script file)
3. Replace placeholders with actual values
4. Make the script executable (Bash/Python) or set appropriate metadata (PowerShell)
5. Update the root README.md scripts list
EOF
}

# Validate script name
validate_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] && [[ ! "$name" =~ ^[a-z0-9]$ ]]; then
    error "Script name must contain only lowercase letters, numbers, and hyphens, and cannot start/end with a hyphen"
  fi
}

# Get author name from git config or prompt
get_author() {
  local author
  author=$(git config user.name 2>/dev/null || echo "")
  if [[ -z "$author" ]]; then
    read -rp "Enter author name: " author
  fi
  echo "$author"
}

# Replace placeholders in a file
replace_placeholders() {
  local file="$1" script_name="$2" description="$3" author="$4" year="$5" date="$6" extension="$7"

  sed -i \
    -e "s/{{SCRIPT_NAME}}/$script_name/g" \
    -e "s/{{DESCRIPTION}}/$description/g" \
    -e "s/{{AUTHOR}}/$author/g" \
    -e "s/{{YEAR}}/$year/g" \
    -e "s/{{DATE}}/$date/g" \
    -e "s/{{EXTENSION}}/$extension/g" \
    "$file"
}

main() {
  # Parse arguments
  local use_powershell=false
  local use_python=false
  local script_name=""
  local description=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case $1 in
      --powershell)
        use_powershell=true
        shift
        ;;
      --python)
        use_python=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      -*)
        error "Unknown option: $1"
        ;;
      *)
        if [[ -z "$script_name" ]]; then
          script_name="$1"
        elif [[ -z "$description" ]]; then
          description="$1"
        else
          error "Too many arguments"
        fi
        shift
        ;;
    esac
  done

  # Validate that only one script type is selected
  local selected_types=0
  [[ "$use_powershell" == "true" ]] && selected_types=$((selected_types + 1))
  [[ "$use_python" == "true" ]] && selected_types=$((selected_types + 1))

  if [[ $selected_types -gt 1 ]]; then
    error "Cannot specify multiple script types. Choose one of: --powershell, --python, or default (Bash)"
  fi

  # Set default description
  if [[ -z "$description" ]]; then
    if [[ "$use_powershell" == "true" ]]; then
      description="A useful PowerShell script"
    elif [[ "$use_python" == "true" ]]; then
      description="A useful Python script"
    else
      description="A useful Ubuntu script"
    fi
  fi

  # Validate inputs
  if [[ -z "$script_name" ]]; then
    usage
    exit 1
  fi

  validate_name "$script_name"

  # Check if directory already exists
  local target_dir="$ROOT_DIR/$script_name"
  if [[ -d "$target_dir" ]]; then
    error "Directory '$script_name' already exists"
  fi

  # Select template directory
  local template_dir
  local script_extension
  local script_type
  if [[ "$use_powershell" == "true" ]]; then
    template_dir="$POWERSHELL_TEMPLATE_DIR"
    script_extension="ps1"
    script_type="PowerShell"
  elif [[ "$use_python" == "true" ]]; then
    template_dir="$PYTHON_TEMPLATE_DIR"
    script_extension="py"
    script_type="Python"
  else
    template_dir="$BASH_TEMPLATE_DIR"
    script_extension="sh"
    script_type="Bash"
  fi

  # Check if template exists
  if [[ ! -d "$template_dir" ]]; then
    error "Template directory not found: $template_dir"
  fi

  # Get metadata
  local author year date
  author=$(get_author)
  year=$(date +%Y)
  date=$(date +"%Y-%m-%d")

  info "Creating new $script_type script: $script_name"
  info "Description: $description"
  info "Author: $author"

  # Create target directory
  mkdir -p "$target_dir"

  # Copy template files
  cp -r "$template_dir"/* "$target_dir/"

  # Rename script file to match script name and extension
  if [[ "$use_powershell" == "true" ]]; then
    mv "$target_dir/script.ps1" "$target_dir/$script_name.ps1"
  elif [[ "$use_python" == "true" ]]; then
    mv "$target_dir/script.py" "$target_dir/$script_name.py"
  else
    mv "$target_dir/script.sh" "$target_dir/$script_name.sh"
  fi

  # Replace placeholders in all files
  for file in "$target_dir"/*; do
    if [[ -f "$file" ]]; then
      replace_placeholders "$file" "$script_name" "$description" "$author" "$year" "$date" "$script_extension"
    fi
  done

  # Make script executable (Bash and Python)
  if [[ "$use_powershell" == "false" ]]; then
    chmod +x "$target_dir/$script_name.$script_extension"
  fi

  info "Created script directory: $script_name/"
  info "Files created:"
  info "  - $script_name/README.md"
  info "  - $script_name/LICENSE"
  if [[ "$use_powershell" == "true" ]]; then
    info "  - $script_name/$script_name.ps1"
  elif [[ "$use_python" == "true" ]]; then
    info "  - $script_name/$script_name.py (executable)"
  else
    info "  - $script_name/$script_name.sh (executable)"
  fi

  # Update root README
  if [[ -x "$ROOT_DIR/bin/list-scripts.sh" ]]; then
    info "Updating root README.md..."
    "$ROOT_DIR/bin/list-scripts.sh"
  else
    warn "Could not update root README.md automatically"
    warn "Run './bin/list-scripts.sh' manually to update the scripts list"
  fi

  info "$script_type script creation completed successfully!"
  info "Next steps:"
  info "  1. Edit $script_name/README.md with specific details"
  info "  2. Implement your logic in $script_name/$script_name.$script_extension"
  info "  3. Test the script thoroughly"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
