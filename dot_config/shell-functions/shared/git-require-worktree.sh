# Return 0 if inside a git work tree, otherwise print "<label>: not inside a
# git work tree." to stderr and return 1. $1 is the caller's label (e.g. the
# command name) so the message matches the calling command.
# Bash 3.2 / zsh compatible.
shell_require_git_worktree() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi
  echo "$1: not inside a git work tree." >&2
  return 1
}
