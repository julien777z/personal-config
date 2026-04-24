# Reset the working tree to HEAD and remove untracked files/dirs. Asks first.
git-reset() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "git-reset: not inside a git work tree."
    return 1
  fi

  echo
  if ! shell_confirm_default_no "Wipe uncommitted changes and remove untracked files/dirs (git reset --hard; git clean -fd)?"; then
    echo "git-reset: cancelled."
    return 0
  fi

  if git reset --hard HEAD && git clean -fd; then
    echo "git-reset: done."
  else
    echo "git-reset: a git command failed."
    return 1
  fi
}
