#!/usr/bin/env bash
# Install every file in terminal/ into ~/.zshrc between managed markers.
# Idempotent: re-running replaces the previously installed block.

set -euo pipefail

ZSHRC="${ZSHRC:-$HOME/.zshrc}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERMINAL_DIR="$REPO_DIR/terminal"
BEGIN_MARKER="# >>> personal-config >>>"
END_MARKER="# <<< personal-config <<<"

if [ ! -d "$TERMINAL_DIR" ]; then
  echo "setup: $TERMINAL_DIR not found" >&2
  exit 1
fi

shopt -s nullglob
files=("$TERMINAL_DIR"/*.sh)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
  echo "setup: no .sh files in $TERMINAL_DIR" >&2
  exit 1
fi

touch "$ZSHRC"

# Strip any previously installed block so this is idempotent.
if grep -qF "$BEGIN_MARKER" "$ZSHRC"; then
  tmp=$(mktemp)
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin { skip=1; next }
    skip && $0 == end { skip=0; next }
    !skip { print }
  ' "$ZSHRC" > "$tmp"
  mv "$tmp" "$ZSHRC"
fi

{
  echo ""
  echo "$BEGIN_MARKER"
  echo "# Managed by personal-config ($REPO_DIR)."
  echo "# Do not edit between these markers; re-run setup.sh to update."
  for f in "${files[@]}"; do
    echo ""
    echo "# --- $(basename "$f") ---"
    cat "$f"
  done
  echo "$END_MARKER"
} >> "$ZSHRC"

echo "setup: installed ${#files[@]} file(s) from terminal/ into $ZSHRC"
echo "setup: run 'source $ZSHRC' or restart your shell to pick up changes."
