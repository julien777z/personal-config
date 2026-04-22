# Recursively delete files/folders whose name ends with " {n}" (space + number),
# which is the naming pattern macOS uses for duplicates created from git repos.
# Prints a preview (up to 50 entries) and asks for confirmation before deleting.
#
# Note: we avoid naming the loop variable `path` because in zsh `path` is a
# special array tied to `$PATH`, and `read -r path` silently fails to assign,
# producing zero matches.
dedup() {
  local -a matches=()
  local match
  while IFS= read -r -d '' match; do
    matches+=("$match")
  done < <(find -E . -depth -regex '.*/[^/]* [0-9]+' -print0 2>/dev/null)

  local total=${#matches[@]}
  if [ "$total" -eq 0 ]; then
    echo "dedup: no duplicates found in $(pwd)"
    return 0
  fi

  echo "dedup: found $total item(s) ending in ' {n}' under $(pwd):"
  echo
  local shown=0
  for match in "${matches[@]}"; do
    [ "$shown" -ge 50 ] && break
    echo "  $match"
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
      for match in "${matches[@]}"; do
        rm -rf -- "$match"
      done
      echo "dedup: deleted $total item(s)."
      ;;
    *)
      echo "dedup: cancelled."
      ;;
  esac
}
