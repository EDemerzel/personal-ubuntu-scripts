#!/usr/bin/env bash

set -euo pipefail

# Update the "Current scripts" section in the root README.md by listing all
# first-level directories that contain at least one .sh, .ps1, or .py file (or a README.md),
# excluding common non-script folders.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
README="$ROOT_DIR/README.md"
START_MARK="<!-- scripts:start -->"
END_MARK="<!-- scripts:end -->"

# Folders to ignore
IGNORE_DIRS=(".git" ".github" ".vscode" "bin")

cd "$ROOT_DIR"

# Build list of candidate directories
mapfile -t DIRS < <(find . -maxdepth 1 -mindepth 1 -type d -printf '%P\n' | sort)

is_ignored() {
  local d="$1"
  for ig in "${IGNORE_DIRS[@]}"; do
    [[ "$d" == "$ig" ]] && return 0
  done
  return 1
}

# Render a bullet line for a directory: "- `dir/` — First sentence from its README.md if present"
render_line() {
  local dir="$1"
  local path="$ROOT_DIR/$dir"
  local summary=""

  if [[ -f "$path/README.md" ]]; then
    # Grab the first non-empty line that isn't a markdown heading marker only
    summary=$(grep -vE '^\s*$' "$path/README.md" | sed -n '1p')
    # Strip leading markdown heading markers like '# ' if present
    summary=${summary###}
    summary=${summary##\#}
    summary=${summary#"${summary%%[![:space:]]*}"}  # Remove leading whitespace
  elif compgen -G "$path/*.sh" >/dev/null || compgen -G "$path/*.ps1" >/dev/null || compgen -G "$path/*.py" >/dev/null; then
    # Detect script type and provide appropriate summary
    local has_bash has_powershell has_python
    has_bash=$(compgen -G "$path/*.sh" >/dev/null && echo "true" || echo "false")
    has_powershell=$(compgen -G "$path/*.ps1" >/dev/null && echo "true" || echo "false")
    has_python=$(compgen -G "$path/*.py" >/dev/null && echo "true" || echo "false")

    local script_types=()
    [[ "$has_bash" == "true" ]] && script_types+=("Bash")
    [[ "$has_powershell" == "true" ]] && script_types+=("PowerShell")
    [[ "$has_python" == "true" ]] && script_types+=("Python")

    if [[ ${#script_types[@]} -gt 1 ]]; then
      # Join with "and" for multiple types
      local last_type="${script_types[-1]}"
      unset 'script_types[-1]'
      summary="$(IFS=", "; echo "${script_types[*]}") and $last_type scripts"
    elif [[ ${#script_types[@]} -eq 1 ]]; then
      summary="${script_types[0]} scripts"
    else
      summary="Scripts"
    fi
  fi

  if [[ -n "$summary" ]]; then
    printf -- "- \`%s/\` — %s\n" "$dir" "$summary"
  else
    printf -- "- \`%s/\`\n" "$dir"
  fi
}

# Generate the new section content
SECTION=""
for d in "${DIRS[@]}"; do
  if is_ignored "$d"; then
    continue
  fi
  # Only include folders that look like script folders
  if compgen -G "$ROOT_DIR/$d/*.sh" >/dev/null || compgen -G "$ROOT_DIR/$d/*.ps1" >/dev/null || compgen -G "$ROOT_DIR/$d/*.py" >/dev/null || [[ -f "$ROOT_DIR/$d/README.md" ]]; then
    SECTION+="$(render_line "$d")\n"
  fi
done

# Replace the content between markers
awk -v start="$START_MARK" -v end="$END_MARK" -v section="$SECTION" '
  BEGIN { printing=1 }
  {
    if ($0 ~ start) { print; printing=0; print section; next }
    if ($0 ~ end) { printing=1 }
    if (printing) print
  }
' "$README" > "$README.tmp"

mv "$README.tmp" "$README"

echo "Updated Current scripts section in README.md"
