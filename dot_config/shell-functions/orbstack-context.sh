# Switch the active Docker CLI context to OrbStack and remove all Docker Desktop
# containers so published ports are not hijacked on localhost.
orbstack-context() {
  local desktop_context="desktop-linux"

  if ! command -v docker >/dev/null 2>&1; then
    echo "orbstack-context: docker not found on PATH." >&2
    return 1
  fi

  local contexts
  contexts=$(docker context ls --format '{{.Name}}' 2>/dev/null)

  if ! echo "$contexts" | grep -qx orbstack; then
    echo "orbstack-context: docker context 'orbstack' was not found. Install OrbStack first." >&2
    return 1
  fi

  if echo "$contexts" | grep -qx "$desktop_context"; then
    local ids
    ids=$(docker --context "$desktop_context" ps -aq 2>/dev/null)
    # shellcheck disable=SC2086
    [ -n "$ids" ] && docker --context "$desktop_context" rm -f $ids >/dev/null 2>&1 || true
  fi

  if ! docker context use orbstack >/dev/null; then
    echo "orbstack-context: failed to switch Docker context to orbstack." >&2
    return 1
  fi

  echo "Docker context set to orbstack."
}
