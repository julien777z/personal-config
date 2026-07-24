# Quarantine malformed refs, purge remote-tracking refs, and re-fetch from origin.
git-fix() {
  shell_require_git_worktree git-fix || return 1

  local git_common_dir
  git_common_dir=$(git rev-parse --git-common-dir) || {
    echo "git-fix: couldn't resolve the shared Git directory." >&2
    return 1
  }
  case "$git_common_dir" in
    /*) ;;
    *)
      git_common_dir=$(cd "$git_common_dir" && pwd -P) || {
        echo "git-fix: couldn't resolve the shared Git directory." >&2
        return 1
      }
      ;;
  esac

  local ref_file ref_name recovery_dir recovery_file
  recovery_dir=
  while IFS= read -r -d '' ref_file; do
    ref_name=${ref_file#"$git_common_dir"/}
    if git check-ref-format "$ref_name" >/dev/null 2>&1; then
      continue
    fi

    if [ -z "$recovery_dir" ]; then
      recovery_dir="$git_common_dir/recovered-invalid-refs/$(date +%Y%m%dT%H%M%S)-$$"
    fi
    recovery_file="$recovery_dir/$ref_name"

    if ! mkdir -p "${recovery_file%/*}" || ! mv "$ref_file" "$recovery_file"; then
      echo "git-fix: couldn't quarantine $ref_name." >&2
      return 1
    fi
    echo "git-fix: quarantined $ref_name at $recovery_file"
  done < <(find "$git_common_dir/refs" -type f ! -name '*.lock' -print0)

  if rm -rf "$git_common_dir/refs/remotes/origin" && \
     mkdir -p "$git_common_dir/refs/remotes/origin" && \
     git fetch origin; then
    echo "git-fix: done."
  else
    echo "git-fix: a command failed." >&2
    return 1
  fi
}
