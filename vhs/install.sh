#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { printf "${BOLD}[install]${RESET} ${GREEN}${*}${RESET}\n" >&2; }
warn() { printf "${BOLD}[install]${RESET} ${YELLOW}${*}${RESET}\n" >&2; }
fail() { printf "${BOLD}[install]${RESET} ${RED}${*}${RESET}\n" >&2; }

SRC=/usr/local/bin/vhs-rec

# If stdout is a pipe, stream the binary directly — the user is doing:
#   docker run ... install > vhs-rec && chmod +x vhs-rec
if [[ ! -t 1 ]]; then
    cat "$SRC"
    exit 0
fi

# Interactive (TTY): just explain how to install.
printf "\n"
printf "${BOLD}${CYAN}Install vhs-rec${RESET}\n"
printf "\n"
printf "Run the following command in the directory where you want to install:\n"
printf "\n"
printf "  ${BOLD}docker run --rm ghcr.io/rondomondo/vhs-rec install > vhs-rec && chmod +x vhs-rec${RESET}\n"
printf "\n"
printf "Then to install system-wide:\n"
printf "\n"
printf "      ${BOLD}install -m 755 vhs-rec /usr/local/bin/vhs-rec${RESET}\n"
printf "\n"
printf "Or use ${BOLD}./vhs-rec${RESET} directly from the current directory.\n"
printf "\n"
