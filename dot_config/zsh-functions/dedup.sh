# Recursively delete files/folders whose name ends with " {n}" (space + number),
# which is the naming pattern macOS uses for duplicates created from git repos.
# Prints a preview (up to 50 entries) and asks for confirmation before deleting.
dedup() {
  local -a matches=()
  local path
  while IFS= read -r -d '' path; do
    matches+=("$path")
  done < <(find . -depth -E -regex '.*/[^/]* [0-9]+' -print0 2>/dev/null)

  local total=${#matches[@]}
  if [ "$total" -eq 0 ]; then
    echo "dedup: no duplicates found in $(pwd)"
    return 0
  fi

  echo "dedup: found $total item(s) ending in ' {n}' under $(pwd):"
  echo
  local shown=0
  for path in "${matches[@]}"; do
    [ "$shown" -ge 50 ] && break
    echo "  $path"
    shown=$((shown + 1))
  done
  if [ "$total" -gt 50 ]; then
    echo "  ...and $((total - 50)) more"
  fi

  echo
  printf "Delete all %d item(s)? [y/N] " "$total"
  local reply
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS])
      for path in "${matches[@]}"; do
        rm -rf -- "$path"
      done
      echo "dedup: deleted $total item(s)."
      ;;
    *)
      echo "dedup: cancelled."
      ;;
  esac
}
