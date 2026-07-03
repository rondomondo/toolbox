#!/bin/bash
set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Set DEBUG=true/1 to enable verbose logging of invocation args via the log() helper.
USE_LOGGING="${DEBUG:-false}"
case "${USE_LOGGING}" in
  true|1)  USE_LOGGING=true  ;;
  false|0) USE_LOGGING=false ;;
  *) printf "ERROR: DEBUG must be true/false/1/0, got '%s'\n" "${USE_LOGGING}" >&2; exit 1 ;;
esac
SCRIPT_NAME=$(basename "$0")

ok()   { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${GREEN}${*}${RESET}\n" >&2; return 0; }
warn() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${YELLOW}${*}${RESET}\n" >&2; return 0; }
fail() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${RED}${*}${RESET}\n" >&2; return 0; }
log()  { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME:$HOSTNAME]${RESET} ${CYAN}${*}${RESET}\n" >&2; return 0; }

log "invoked with args '$*'"

if [ $# -gt 0 ] && [ "$1" = "install" ]; then
    log "install was requested with args: '$*'"
    shift
    exec /install.sh "$@"
fi

if [ -n "${HOST_PWD:-}" ]; then
    cd "$HOST_PWD"
    [ "$HOST_PWD" = "$(pwd)" ] && ok "successfully changed directory to $HOST_PWD" || { fail "failed to change dir to $HOST_PWD"; exit 1; }
fi

# Strip a leading 'mmdc' token so callers can write `docker run ... mmdc -i input -o output`
MMDC=/home/mermaidcli/node_modules/.bin/mmdc
if [ $# -gt 0 ] && { [ "$1" = "mmdc" ] || [ "$1" = "$MMDC" ]; }; then
    shift
fi

if [ -n "${USE_SHELL:-}" ]; then
    log "USE_SHELL was set so dropping into shell: $USE_SHELL"
    exec "$(which "${USE_SHELL}")"
else
    log "calling $MMDC with args: '$*'"
    exec "$MMDC" -p /puppeteer-config.json "$@"
fi

fail "$0: should never reach here"; exit 1
