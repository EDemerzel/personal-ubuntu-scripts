#!/usr/bin/env bash
set -euo pipefail

# {{SCRIPT_NAME}}.sh - {{DESCRIPTION}}
#
# Usage: ./{{SCRIPT_NAME}}.sh [options]
#
# Author: {{AUTHOR}}
# Created: {{DATE}}

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Function to check if running as root (if needed)
check_root() {
  if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
  fi
}

# Function to check dependencies
check_dependencies() {
  local deps=("curl" "wget" "git")  # Example dependencies
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      error "Required dependency '$dep' is not installed"
    fi
  done
}

# Main function
main() {
  info "Starting {{SCRIPT_NAME}}"

  # Uncomment if root check is needed
  # check_root

  # Uncomment if dependency check is needed
  # check_dependencies

  # Your script logic here
  echo "Hello from {{SCRIPT_NAME}}!"

  info "{{SCRIPT_NAME}} completed successfully"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
