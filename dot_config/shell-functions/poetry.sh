# Wrapper around `poetry run` that adds two niceties on top of the real
# `poetry` binary:
#
#   poetry run <target> [args...]
#     Walks up from $PWD looking for a `.poetry_targets.yaml` file. If
#     found and <target> is listed there, runs each command for that
#     target (top to bottom) before delegating to the real `poetry run`.
#     Useful for, e.g., spawning a Docker compose stack the package
#     needs in order to run locally.
#
#   poetry run                (no arguments)
#     Walks up from $PWD looking for `pyproject.toml`, parses
#     `[tool.poetry.scripts]` (and `[project.scripts]`), and shows an
#     arrow-key picker. The selected entry is then handed back through
#     this wrapper, so its `.poetry_targets.yaml` setup runs as well.
#
#   anything else (`poetry install`, `poetry add ...`, ...)
#     Forwarded straight through to the real `poetry`.
#
# When the script can't help (no `.poetry_targets.yaml` and target
# isn't a script in pyproject, no pyproject.toml at all, parser sees
# nothing useful), it just calls `command poetry ...` so regular Poetry
# handles the request and prints its own error if there is one.
#
# `.poetry_targets.yaml` format — top-level keys are package names,
# values are lists of shell commands:
#
#   my-cli:
#     - docker compose up -d
#     - sleep 2
#   worker:
#     - echo "warming worker"

poetry() {
  if [ "$1" != "run" ]; then
    command poetry "$@"
    return $?
  fi
  shift
  _poetry_run "$@"
}

# Walk up from $PWD looking for $1; print its absolute path on stdout.
_poetry_find_up() {
  local name="$1"
  local dir="$PWD"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -e "$dir/$name" ]; then
      printf '%s\n' "$dir/$name"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

# Print one command per line for target $2 in YAML file $1.
# Handles the simple, expected format:
#   <name>:
#     - <command>
#     - <command>
# Strips surrounding quotes and trailing inline comments.
_poetry_targets_for() {
  awk -v want="$2" '
    /^[ \t]*#/ { next }
    /^[ \t]*$/ { next }
    /^[^ \t]/ {
      if (hit) exit
      key = $0
      sub(/:.*$/, "", key)
      sub(/[ \t]+$/, "", key)
      if (key == want) hit = 1
      next
    }
    hit && /^[ \t]+-[ \t]/ {
      cmd = $0
      sub(/^[ \t]+-[ \t]+/, "", cmd)
      sub(/[ \t]+#.*$/, "", cmd)
      if (cmd ~ /^".*"$/ || cmd ~ /^\047.*\047$/) {
        cmd = substr(cmd, 2, length(cmd) - 2)
      }
      print cmd
    }
  ' "$1"
}

# Print "<name><TAB><entry>" for each script defined in pyproject.toml $1.
_poetry_scripts_from_pyproject() {
  awk '
    /^\[tool\.poetry\.scripts\]/ { sec = 1; next }
    /^\[project\.scripts\]/      { sec = 1; next }
    /^\[/                        { sec = 0; next }
    sec && /^[A-Za-z0-9_.-]+[ \t]*=/ {
      name = $0; sub(/[ \t]*=.*/, "", name)
      val  = $0; sub(/^[^=]*=[ \t]*/, "", val)
      sub(/[ \t]+$/, "", val)
      if (val ~ /^".*"$/ || val ~ /^\047.*\047$/) {
        val = substr(val, 2, length(val) - 2)
      }
      printf "%s\t%s\n", name, val
    }
  ' "$1"
}

# Read one keystroke from /dev/tty and store a symbolic name
# (UP / DOWN / ENTER / QUIT / OTHER) in the variable named by $1.
_poetry_read_key_into() {
  local _b1 _b2 _b3
  if [ -n "${ZSH_VERSION:-}" ]; then
    read -s -k 1 _b1 </dev/tty
  else
    IFS= read -rsn1 _b1 </dev/tty
  fi
  if [ "$_b1" = $'\033' ]; then
    if [ -n "${ZSH_VERSION:-}" ]; then
      read -s -k 1 _b2 </dev/tty
      read -s -k 1 _b3 </dev/tty
    else
      IFS= read -rsn1 _b2 </dev/tty
      IFS= read -rsn1 _b3 </dev/tty
    fi
    case "$_b2$_b3" in
      '[A') eval "$1=UP" ;;
      '[B') eval "$1=DOWN" ;;
      *)    eval "$1=OTHER" ;;
    esac
  elif [ -z "$_b1" ]; then
    eval "$1=ENTER"
  else
    case "$_b1" in
      q|Q) eval "$1=QUIT" ;;
      *)   eval "$1=OTHER" ;;
    esac
  fi
}

# Interactive arrow-key picker. Each argument is a "name<TAB>entry"
# row. Renders the table on /dev/tty and prints the selected name on
# stdout. Returns non-zero if the user quits (q / Esc).
_poetry_pick() {
  local -a items
  items=("$@")
  local count=${#items[@]}
  local i nm en maxw=0

  # Compute width of the name column for alignment.
  for ((i = 0; i < count; i++)); do
    nm=${items[$i]%%$'\t'*}
    if [ ${#nm} -gt $maxw ]; then maxw=${#nm}; fi
  done

  local cur=0 key
  printf 'Select a Poetry script (arrow keys to move, Enter to run, q to cancel):\n' >/dev/tty
  printf '\033[?25l' >/dev/tty

  _poetry_pick_draw() {
    local j n e
    for ((j = 0; j < count; j++)); do
      n=${items[$j]%%$'\t'*}
      e=${items[$j]#*$'\t'}
      if [ "$j" -eq "$cur" ]; then
        printf '\033[7m> %-*s  %s\033[0m\n' "$maxw" "$n" "$e" >/dev/tty
      else
        printf '  %-*s  %s\n' "$maxw" "$n" "$e" >/dev/tty
      fi
    done
  }

  _poetry_pick_draw
  while :; do
    _poetry_read_key_into key
    case "$key" in
      UP)    cur=$((cur - 1)); [ $cur -lt 0 ] && cur=$((count - 1)) ;;
      DOWN)  cur=$((cur + 1)); [ $cur -ge $count ] && cur=0 ;;
      ENTER) break ;;
      QUIT)
        printf '\033[?25h' >/dev/tty
        return 1
        ;;
      *) ;;
    esac
    printf '\033[%dA' "$count" >/dev/tty
    _poetry_pick_draw
  done
  printf '\033[?25h' >/dev/tty
  printf '%s\n' "${items[$cur]%%$'\t'*}"
}

_poetry_run() {
  # No-arg form: pick a script from pyproject.toml, then re-enter.
  if [ $# -eq 0 ]; then
    local pyproject
    if ! pyproject=$(_poetry_find_up "pyproject.toml"); then
      command poetry run
      return $?
    fi

    local -a scripts
    scripts=()
    local s
    while IFS= read -r s; do
      [ -n "$s" ] && scripts+=("$s")
    done < <(_poetry_scripts_from_pyproject "$pyproject")

    if [ ${#scripts[@]} -eq 0 ]; then
      command poetry run
      return $?
    fi

    local pick
    if ! pick=$(_poetry_pick "${scripts[@]}"); then
      echo "poetry: cancelled." >&2
      return 130
    fi
    _poetry_run "$pick"
    return $?
  fi

  local target="$1"
  shift

  local targets_file
  if targets_file=$(_poetry_find_up ".poetry_targets.yaml"); then
    local cmd
    while IFS= read -r cmd; do
      [ -z "$cmd" ] && continue
      printf '\033[2m[poetry-wrapper] %s\033[0m\n' "$cmd"
      eval "$cmd" || {
        echo "poetry: pre-command failed for target '$target': $cmd" >&2
        return 1
      }
    done < <(_poetry_targets_for "$targets_file" "$target")
  fi

  command poetry run "$target" "$@"
}
