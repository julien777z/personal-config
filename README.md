# personal-config

My macOS dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Install

```
bash setup.sh
```

Installs chezmoi to `~/.local/bin`, points it at this repo, and applies the config. An existing `~/.zshrc` (if any) is backed up to `~/.zshrc.pre-chezmoi.bak` on first run.

## Layout

- `dot_zshrc` → `~/.zshrc`
- `dot_config/zsh-functions/*.sh` → `~/.config/zsh-functions/*.sh` (sourced from `.zshrc`)

## Adding a function

Drop a new `*.sh` into `dot_config/zsh-functions/` and run `chezmoi apply`.
