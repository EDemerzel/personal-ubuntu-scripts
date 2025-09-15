#!/usr/bin/env bash
set -euo pipefail

# Update the "Current scripts" section in the root README.md by listing all
# first-level directories that contain at least one .sh file (or a README.md),
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
    summary=$(echo "$summary" | sed 's/^\s\+//')
  elif compgen -G "$path/*.sh" >/dev/null; then
    summary="Shell scripts"
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
  if compgen -G "$ROOT_DIR/$d/*.sh" >/dev/null || [[ -f "$ROOT_DIR/$d/README.md" ]]; then
    SECTION+="$(render_line "$d")\n"
  fi
done

# Escape slashes for sed safety
START_RE=$(printf '%s\n' "$START_MARK" | sed 's/[^^]/[&]/g; s/\^/\\^/g')
END_RE=$(printf '%s\n' "$END_MARK" | sed 's/[^^]/[&]/g; s/\^/\\^/g')

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
