# Reset the working tree to HEAD and remove untracked files/dirs.
git-reset() {
  shell_require_git_worktree git-reset || return 1

  echo
  if ! shell_confirm_default_no "Wipe uncommitted changes and remove untracked files/dirs?"; then
    echo "git-reset: cancelled."
    return 0
  fi

  if git reset --hard HEAD && git clean -fd; then
    echo "git-reset: done."
  else
    echo "git-reset: a git command failed." >&2
    return 1
  fi
}
