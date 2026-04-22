#!/usr/bin/env bash
# Install chezmoi, point it at this repo, and apply. Idempotent; macOS-only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

install_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    echo "setup: chezmoi already installed at $(command -v chezmoi)"
    return
  fi
  if [ -x "$BIN_DIR/chezmoi" ]; then
    echo "setup: chezmoi already installed at $BIN_DIR/chezmoi"
    return
  fi
  mkdir -p "$BIN_DIR"
  echo "setup: installing chezmoi to $BIN_DIR"
  sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$BIN_DIR"
}

configure_chezmoi() {
  local cfg_dir="$HOME/.config/chezmoi"
  local cfg_file="$cfg_dir/chezmoi.toml"
  local line="sourceDir = \"$REPO_DIR\""
  mkdir -p "$cfg_dir"
  if [ ! -f "$cfg_file" ]; then
    echo "$line" > "$cfg_file"
    echo "setup: wrote $cfg_file"
    return
  fi
  if grep -qxF "$line" "$cfg_file"; then
    echo "setup: chezmoi sourceDir already $REPO_DIR"
    return
  fi
  if grep -qE '^[[:space:]]*sourceDir[[:space:]]*=' "$cfg_file"; then
    echo "setup: $cfg_file already has a sourceDir that doesn't match" >&2
    echo "setup: update it manually to: $line" >&2
    return 1
  fi
  # Existing config without a sourceDir line — append, don't truncate.
  printf '\n%s\n' "$line" >> "$cfg_file"
  echo "setup: appended sourceDir to $cfg_file"
}

backup_file() {
  local src="$1"
  local bak="${src}.pre-chezmoi.bak"
  [ -f "$src" ] || return 0
  if [ -e "$bak" ]; then
    echo "setup: $bak already exists; leaving it alone"
    return
  fi
  cp -p "$src" "$bak"
  echo "setup: backed up existing $src to $bak"
}

install_chezmoi
# Make sure the just-installed binary is resolvable for the apply step,
# regardless of whether chezmoi was already on PATH elsewhere.
export PATH="$BIN_DIR:$PATH"
configure_chezmoi
backup_file "$HOME/.zshrc"
backup_file "$HOME/.bash_profile"
chezmoi apply

echo "setup: done. Start a new shell or 'source ~/.zshrc' (or ~/.bash_profile) to pick up changes."
for bak in "$HOME/.zshrc.pre-chezmoi.bak" "$HOME/.bash_profile.pre-chezmoi.bak"; do
  [ -e "$bak" ] && echo "setup: review $bak and fold any customizations into $REPO_DIR/"
done
