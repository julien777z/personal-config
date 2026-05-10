# Purge stale remote-tracking refs and re-fetch from origin.
git-purge() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "git-purge: not inside a git work tree." >&2
    return 1
  fi

  if rm -rf .git/refs/remotes/origin && \
     mkdir -p .git/refs/remotes/origin && \
     git fetch origin; then
    echo "git-purge: done."
  else
    echo "git-purge: a command failed." >&2
    return 1
  fi
}
