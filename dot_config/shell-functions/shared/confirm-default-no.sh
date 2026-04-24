# Prompt with "[y/N]" (default no). Returns 0 if the user answers y/yes, 1 otherwise.
# Bash 3.2 / zsh compatible.
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
