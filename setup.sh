#!/usr/bin/env bash
# Install chezmoi, point it at this repo, and apply. Idempotent; macOS-only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CANONICAL_REPO="$HOME/personal-config"

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
  # Existing config without a sourceDir line — prepend so it stays at the
  # TOML root, even if the file already has [section] headers.
  local tmp
  tmp=$(mktemp)
  { printf '%s\n' "$line"; cat "$cfg_file"; } > "$tmp"
  mv "$tmp" "$cfg_file"
  echo "setup: prepended sourceDir to $cfg_file"
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

# Ensure `~/personal-config` resolves to this repo, so `update-bash`, the
# README instructions, and muscle memory all work regardless of where the
# repo was actually cloned.
ensure_canonical_repo() {
  if [ "$REPO_DIR" = "$CANONICAL_REPO" ]; then
    return
  fi
  if [ -L "$CANONICAL_REPO" ]; then
    local target
    target=$(readlink "$CANONICAL_REPO")
    if [ "$target" = "$REPO_DIR" ]; then
      echo "setup: $CANONICAL_REPO already symlinked to $REPO_DIR"
      return
    fi
    echo "setup: $CANONICAL_REPO is a symlink to $target; leaving it alone" >&2
    return
  fi
  if [ -e "$CANONICAL_REPO" ]; then
    echo "setup: $CANONICAL_REPO exists and isn't a symlink; leaving it alone" >&2
    return
  fi
  ln -s "$REPO_DIR" "$CANONICAL_REPO"
  echo "setup: symlinked $CANONICAL_REPO -> $REPO_DIR"
}

install_chezmoi
# Make sure the just-installed binary is resolvable for the apply step,
# regardless of whether chezmoi was already on PATH elsewhere.
export PATH="$BIN_DIR:$PATH"
ensure_canonical_repo
configure_chezmoi
backup_file "$HOME/.zshrc"
backup_file "$HOME/.bash_profile"
chezmoi apply

echo "setup: done. Start a new shell or 'source ~/.zshrc' (or ~/.bash_profile) to pick up changes."
for bak in "$HOME/.zshrc.pre-chezmoi.bak" "$HOME/.bash_profile.pre-chezmoi.bak"; do
  if [ -e "$bak" ]; then
    echo "setup: review $bak and fold any customizations into $REPO_DIR/"
  fi
done
