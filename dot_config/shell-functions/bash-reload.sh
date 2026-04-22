# Replace the current shell with a fresh one so newly-added functions/aliases
# become available without closing the terminal tab. Keeps cwd and exported
# env vars; drops shell-local state (defined-at-runtime aliases/functions,
# unsaved history lines, background jobs).
bash-reload() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    exec zsh
  elif [ -n "${BASH_VERSION:-}" ]; then
    exec bash -l
  else
    exec "${SHELL:-sh}"
  fi
}
