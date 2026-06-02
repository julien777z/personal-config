# Cross-cutting helpers shared by several commands. Sourced before the
# top-level shell-functions scripts by both the zsh and bash entry points.
# Bash 3.2 / zsh compatible.

# Prompt with "[y/N]" (default no). Returns 0 if the user answers y/yes, 1 otherwise.
shell_confirm_default_no() {
  local reply
  printf '%s [y/N] ' "$1"
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Return 0 if inside a git work tree, otherwise print "<label>: not inside a
# git work tree." to stderr and return 1. $1 is the caller's label (e.g. the
# command name) so the message matches the calling command.
shell_require_git_worktree() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi
  echo "$1: not inside a git work tree." >&2
  return 1
}
