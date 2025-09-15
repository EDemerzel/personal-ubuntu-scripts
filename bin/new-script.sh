#!/usr/bin/env bash
set -euo pipefail

# new-script.sh - Create a new script folder from template
#
# Usage: ./bin/new-script.sh <script-name> [description]
#
# Creates a new script directory with boilerplate files from the template.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/script-template"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}Error: $*${NC}" >&2
  exit 1
}

info() {
  echo -e "${GREEN}Info: $*${NC}"
}

warn() {
  echo -e "${YELLOW}Warning: $*${NC}"
}

usage() {
  cat << EOF
Usage: $0 <script-name> [description]

Creates a new script directory with boilerplate files.

Arguments:
  script-name   Name of the script (will be used for directory and main script file)
  description   Optional description of what the script does

Examples:
  $0 backup-dotfiles "Backup user dotfiles to cloud storage"
  $0 setup-dev-env "Configure development environment"

The script will:
1. Create a new directory named <script-name>
2. Copy template files (README.md, LICENSE, script.sh)
3. Replace placeholders with actual values
4. Make the script executable
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
  local file="$1" script_name="$2" description="$3" author="$4" year="$5" date="$6"

  sed -i \
    -e "s/{{SCRIPT_NAME}}/$script_name/g" \
    -e "s/{{DESCRIPTION}}/$description/g" \
    -e "s/{{AUTHOR}}/$author/g" \
    -e "s/{{YEAR}}/$year/g" \
    -e "s/{{DATE}}/$date/g" \
    "$file"
}

main() {
  # Parse arguments
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local script_name="$1"
  local description="${2:-A useful Ubuntu script}"

  # Validate inputs
  validate_name "$script_name"

  # Check if directory already exists
  local target_dir="$ROOT_DIR/$script_name"
  if [[ -d "$target_dir" ]]; then
    error "Directory '$script_name' already exists"
  fi

  # Check if template exists
  if [[ ! -d "$TEMPLATE_DIR" ]]; then
    error "Template directory not found: $TEMPLATE_DIR"
  fi

  # Get metadata
  local author year date
  author=$(get_author)
  year=$(date +%Y)
  date=$(date +"%Y-%m-%d")

  info "Creating new script: $script_name"
  info "Description: $description"
  info "Author: $author"

  # Create target directory
  mkdir -p "$target_dir"

  # Copy template files
  cp -r "$TEMPLATE_DIR"/* "$target_dir/"

  # Rename script.sh to match script name
  mv "$target_dir/script.sh" "$target_dir/$script_name.sh"

  # Replace placeholders in all files
  for file in "$target_dir"/*; do
    if [[ -f "$file" ]]; then
      replace_placeholders "$file" "$script_name" "$description" "$author" "$year" "$date"
    fi
  done

  # Make script executable
  chmod +x "$target_dir/$script_name.sh"

  info "Created script directory: $script_name/"
  info "Files created:"
  info "  - $script_name/README.md"
  info "  - $script_name/LICENSE"
  info "  - $script_name/$script_name.sh (executable)"

  # Update root README
  if [[ -x "$ROOT_DIR/bin/list-scripts.sh" ]]; then
    info "Updating root README.md..."
    "$ROOT_DIR/bin/list-scripts.sh"
  else
    warn "Could not update root README.md automatically"
    warn "Run './bin/list-scripts.sh' manually to update the scripts list"
  fi

  info "Script creation completed successfully!"
  info "Next steps:"
  info "  1. Edit $script_name/README.md with specific details"
  info "  2. Implement your logic in $script_name/$script_name.sh"
  info "  3. Test the script thoroughly"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
