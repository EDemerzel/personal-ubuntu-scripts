#!/usr/bin/env bash
set -euo pipefail

# {{SCRIPT_NAME}}.sh - {{DESCRIPTION}}
#
# Usage: ./{{SCRIPT_NAME}}.sh [options]
#
# Author: {{AUTHOR}}
# Created: {{DATE}}

# Script directory for relative paths
# shellcheck disable=SC2034  # May be used by template consumers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  log_info "Starting {{SCRIPT_NAME}}"
  log_debug "Debug mode enabled"

  # Uncomment if root check is needed
  # check_root

  # Uncomment if dependency check is needed
  # check_dependencies

  # Your script logic here
  echo "Hello from {{SCRIPT_NAME}}!"

  log_info "{{SCRIPT_NAME}} completed successfully"
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
