# Purge stale remote-tracking refs and re-fetch from origin.
git-purge() {
  shell_require_git_worktree git-purge || return 1

  if rm -rf .git/refs/remotes/origin && \
     mkdir -p .git/refs/remotes/origin && \
     git fetch origin; then
    echo "git-purge: done."
  else
    echo "git-purge: a command failed." >&2
    return 1
  fi
}
