# Personal Config

Utilities I use often.

Uses [chezmoi](https://www.chezmoi.io/) for dotfile managment.

## Install

```
bash setup.sh
```

Installs chezmoi to `~/.local/bin`, points it at this repo, and applies the config. Existing `~/.zshrc` and/or `~/.bash_profile` are backed up to `*.pre-chezmoi.bak` on first run.

## Layout

- `dot_zshrc` → `~/.zshrc`
- `dot_bash_profile` → `~/.bash_profile`
- `dot_config/shell-functions/*.sh` → `~/.config/shell-functions/*.sh` (sourced by both the zsh and bash entry points)

## Adding a function

Drop a new `*.sh` into `dot_config/shell-functions/` and run `chezmoi apply`. Functions must be bash-3.2 compatible (macOS's system bash) if you want them to work from `.bash_profile` as well as zsh.
