# Refresh the shell config: git pull in the personal-config repo (if it is one),
# then `chezmoi apply` to copy the latest versions into place.
# Named "bash-update" because that's easier to remember than "chezmoi apply".
bash-update() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "bash-update: chezmoi not on PATH (did you run setup.sh?)" >&2
    return 1
  fi
  local src
  src=$(chezmoi source-path 2>/dev/null) || {
    echo "bash-update: couldn't resolve chezmoi source-path" >&2
    return 1
  }
  if [ -d "$src/.git" ]; then
    echo "bash-update: pulling latest in $src"
    ( cd "$src" && git pull --ff-only ) || {
      echo "bash-update: git pull failed; not applying" >&2
      return 1
    }
  fi
  echo "bash-update: running chezmoi apply"
  chezmoi apply
  bash-reload
}
