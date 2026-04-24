# Recursively delete files/folders whose name ends with " {n}" (space + number),
# which is the naming pattern macOS uses for duplicates created from git repos.
# Prints a preview (up to 50 entries) and asks for confirmation before deleting.
#
# Note: we avoid `path` and `match` as variable names because both are special
# in zsh (`path` is tied to `$PATH`; `match` is an array populated by `=~`
# and `(#m)` glob flags), and `read -r` into either can silently fail.
dedup() {
  local -a matches=()
  local item
  while IFS= read -r -d '' item; do
    matches+=("$item")
  done < <(find -E . -depth -regex '.*/[^/]* [0-9]+' -print0 2>/dev/null)

  local total=${#matches[@]}
  if [ "$total" -eq 0 ]; then
    echo "dedup: no duplicates found in $(pwd)"
    return 0
  fi

  echo "dedup: found $total item(s) ending in ' {n}' under $(pwd):"
  echo
  local shown=0
  for item in "${matches[@]}"; do
    [ "$shown" -ge 50 ] && break
    echo "  $item"
    shown=$((shown + 1))
  done
  if [ "$total" -gt 50 ]; then
    echo "  ...and $((total - 50)) more"
  fi

  echo
  local q
  q=$(printf "Delete all %d item(s)?" "$total")
  if shell_confirm_default_no "$q"; then
    for item in "${matches[@]}"; do
      rm -rf -- "$item"
    done
    echo "dedup: deleted $total item(s)."
  else
    echo "dedup: cancelled."
  fi
}
