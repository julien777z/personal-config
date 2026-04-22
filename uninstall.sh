#!/usr/bin/env bash
# Revert the filesystem changes that setup.sh + chezmoi apply made.
# Idempotent. Does not touch this repo or the chezmoi binary.
# Intentionally avoids `chezmoi purge` because that would delete the
# source directory — i.e. this repo.

set -euo pipefail

# If chezmoi config is present, the entry points are chezmoi-managed.
# Once that's gone we can't safely assume a bare .zshrc is ours, so we
# only remove-without-backup when chezmoi config still exists.
chezmoi_configured=0
[ -d "$HOME/.config/chezmoi" ] && chezmoi_configured=1

restore_or_remove() {
  local target="$1"
  local bak="${target}.pre-chezmoi.bak"
  if [ -e "$bak" ]; then
    mv -f "$bak" "$target"
    echo "uninstall: restored $target from $bak"
  elif [ "$chezmoi_configured" = "1" ] && { [ -e "$target" ] || [ -L "$target" ]; }; then
    rm -f "$target"
    echo "uninstall: removed $target (no backup to restore)"
  fi
}

restore_or_remove "$HOME/.zshrc"
restore_or_remove "$HOME/.bash_profile"

if [ -d "$HOME/.config/shell-functions" ]; then
  rm -rf "$HOME/.config/shell-functions"
  echo "uninstall: removed ~/.config/shell-functions"
fi

if [ -d "$HOME/.config/chezmoi" ]; then
  rm -rf "$HOME/.config/chezmoi"
  echo "uninstall: removed ~/.config/chezmoi (config + state)"
fi

echo "uninstall: done. Start a new shell to pick up the restored config."
echo "uninstall: the chezmoi binary at ~/.local/bin/chezmoi and this repo were left in place."
