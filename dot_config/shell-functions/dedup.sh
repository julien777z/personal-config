# Recursively delete files/folders whose basename looks like a macOS duplicate:
# something, then a space, then a short counter (1-3 digits), optionally followed
# by a dot and extension (e.g. "foo 2", "foo 2.html"). Counters longer than three
# digits are ignored so names like "report 2024.pdf" are not treated as duplicates.
# Prints a preview (up to 50 entries) and asks for confirmation before deleting.
#
# Note: we avoid `path` and `match` as variable names because both are special
# in zsh (`path` is tied to `$PATH`; `match` is an array populated by `=~`
# and `(#m)` glob flags), and `read -r` into either can silently fail.
dedup() {
  local -a matches=()
  local -a skip_dirs=(node_modules .venv)
  local item skip_dir
  while IFS= read -r -d '' item; do
    for skip_dir in "${skip_dirs[@]}"; do
      case "$item" in
        "./$skip_dir"|"./$skip_dir"/*|"*/$skip_dir"/*)
          continue 2
          ;;
      esac
    done
    matches+=("$item")
  done < <(find -E . -depth -regex '.*/[^/]* [0-9]{1,3}(\.[^/]+)?' -print0 2>/dev/null)

  local total=${#matches[@]}
  if [ "$total" -eq 0 ]; then
    echo "dedup: no duplicates found in $(pwd)"
    return 0
  fi

  echo "dedup: found $total item(s) matching macOS duplicate names (... N or ... N.ext, N is 1-3 digits) under $(pwd):"
  echo
  for item in "${matches[@]:0:50}"; do
    echo "  $item"
  done
  if [ "$total" -gt 50 ]; then
    echo "  ...and $((total - 50)) more"
  fi

  echo
  if shell_confirm_default_no "Delete all $total item(s)?"; then
    for item in "${matches[@]}"; do
      rm -rf -- "$item"
    done
    echo "dedup: deleted $total item(s)."
  else
    echo "dedup: cancelled."
  fi
}
