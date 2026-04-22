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

Drop a new `*.sh` into `dot_config/shell-functions/` and run `update-bash` (or `chezmoi apply`). Functions must be bash-3.2 compatible (macOS's system bash) if you want them to work from `.bash_profile` as well as zsh, and avoid `path` as a variable name (it's a tied array in zsh).

## Pulling updates

```
update-bash
```

Defined in `dot_config/shell-functions/update-bash.sh`. Does `git pull` in the repo (via `chezmoi source-path`) then `chezmoi apply`.

After adding or editing a function, `reload-bash` (defined in `reload-bash.sh`) re-execs the current shell so the new definitions are picked up without closing the tab.

## Uninstall

```
bash uninstall.sh
```

Restores `~/.zshrc` and `~/.bash_profile` from their `*.pre-chezmoi.bak` backups (or removes them if no backup exists), removes `~/.config/shell-functions/`, and removes `~/.config/chezmoi/`. Leaves this repo and the chezmoi binary (`~/.local/bin/chezmoi`) alone.
