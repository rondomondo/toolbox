#!/bin/bash
set -uo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Set DEBUG=true/1 to enable verbose logging via the log() helpers.
USE_LOGGING="${DEBUG:-false}"
case "${USE_LOGGING}" in
  true|1)  USE_LOGGING=true  ;;
  false|0) USE_LOGGING=false ;;
  *) printf "ERROR: DEBUG must be true/false/1/0, got '%s'\n" "${USE_LOGGING}" >&2; exit 1 ;;
esac
SCRIPT_NAME=$(basename "$0")

ok()   { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${GREEN}${*}${RESET}\n"  >&2; return 0; }
warn() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${YELLOW}${*}${RESET}\n" >&2; return 0; }
fail() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${RED}${*}${RESET}\n"    >&2; return 0; }
log()  { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${CYAN}${*}${RESET}\n"   >&2; return 0; }

log "invoked with args '$*'"

# Delegate to install.sh when the first argument is "install".
if [ $# -gt 0 ] && [ "$1" = "install" ]; then
  log "install was requested with args: '$*'"
  shift
  exec /install.sh "$@"
fi

# If HOST_PWD is set (e.g. bind-mounted from the host), switch into it so
# relative file paths resolve correctly.
if [ -n "${HOST_PWD:-}" ]; then
  cd "$HOST_PWD"
  [ "$HOST_PWD" = "$(pwd)" ] \
    && ok "successfully changed directory to $HOST_PWD" \
    || { fail "failed to change dir to $HOST_PWD"; exit 1; }
fi

# Drop into an arbitrary shell when USE_SHELL is set (useful for debugging).
if [ -n "${USE_SHELL:-}" ]; then
  log "USE_SHELL set — dropping into shell: $USE_SHELL"
  exec "$(which "$USE_SHELL")"
fi

STRIP="$(which strip.py)" 

if [ $# -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
  exec "$(which python)" "$STRIP" --help
  exit 0
fi

# Default mode is strip; --check performs a dry-run check instead.
MODE="strip"
if [ $# -gt 0 ] && [ "$1" = "--check" ]; then
  MODE="check"
  shift
fi

log "calling $(which python) $STRIP with args: '$*'"
if [ "$MODE" = "check" ]; then
  exec "$(which python)" "$STRIP" "--check" "$@"
else
  exec "$(which python)" "$STRIP" "$@"
fi

fail "$0: should never reach here"; exit 1
