#!/usr/bin/env bash
# Install chezmoi, point it at this repo, and apply. Idempotent; macOS-only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CHEZMOI="$BIN_DIR/chezmoi"

install_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    echo "setup: chezmoi already installed at $(command -v chezmoi)"
    return
  fi
  if [ -x "$CHEZMOI" ]; then
    echo "setup: chezmoi already installed at $CHEZMOI"
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
  if [ -f "$cfg_file" ] && grep -qxF "$line" "$cfg_file"; then
    echo "setup: chezmoi sourceDir already $REPO_DIR"
    return
  fi
  echo "$line" > "$cfg_file"
  echo "setup: wrote $cfg_file"
}

backup_zshrc() {
  local zshrc="$HOME/.zshrc"
  local bak="$HOME/.zshrc.pre-chezmoi.bak"
  [ -f "$zshrc" ] || return 0
  if [ -e "$bak" ]; then
    echo "setup: $bak already exists; leaving it alone"
    return
  fi
  cp -p "$zshrc" "$bak"
  echo "setup: backed up existing ~/.zshrc to $bak"
}

install_chezmoi
configure_chezmoi
backup_zshrc
"$CHEZMOI" apply

echo "setup: done. Start a new shell or 'source ~/.zshrc' to pick up changes."
if [ -e "$HOME/.zshrc.pre-chezmoi.bak" ]; then
  echo "setup: review ~/.zshrc.pre-chezmoi.bak and fold any customizations into $REPO_DIR/dot_zshrc"
fi
