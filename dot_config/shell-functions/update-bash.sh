# Refresh the shell config: git pull in the personal-config repo (if it is one),
# then `chezmoi apply` to copy the latest versions into place.
# Named "update-bash" because that's easier to remember than "chezmoi apply".
update-bash() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "update-bash: chezmoi not on PATH (did you run setup.sh?)" >&2
    return 1
  fi
  local src
  src=$(chezmoi source-path 2>/dev/null) || {
    echo "update-bash: couldn't resolve chezmoi source-path" >&2
    return 1
  }
  if [ -d "$src/.git" ]; then
    echo "update-bash: pulling latest in $src"
    ( cd "$src" && git pull --ff-only ) || {
      echo "update-bash: git pull failed; not applying" >&2
      return 1
    }
  fi
  echo "update-bash: running chezmoi apply"
  chezmoi apply
}
