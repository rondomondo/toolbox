#!/usr/bin/env bash
# =============================================================================
# scaffold-tool.sh
#
# Bootstrap a new toolbox tool with all the skill-aware scaffolding in place.
# Creates the toolbox subdirectory, a matching agent-skills-toolbox/skills/
# entry, and optionally patches the root Makefile.
#
# Usage:
#   scaffold-tool.sh <name> [--type script|docker] [--description "..."]
#                           [--toolbox-dir DIR] [--skills-dir DIR]
#                           [--no-makefile-patch] [--dry-run]
#
#   <name>                   Tool name (kebab-case, e.g. my-tool)
#   --type script|docker     Type of tool (default: script)
#   --description "..."      One-line description for SKILL.md and README.md
#   --toolbox-dir DIR        Path to toolbox root (default: parent of this script)
#   --skills-dir DIR         Path to agent-skills-toolbox/skills/ (default: ~/Code/agent-skills-toolbox/skills)
#   --no-makefile-patch      Skip patching the root Makefile
#   --dry-run                Print what would be created without writing files
#
# What it creates:
#   toolbox/<name>/
#     Makefile        -- skill-aware, install/uninstall/sync-skill targets
#     SKILL.md        -- agent instruction document (frontmatter + steps)
#     README.md       -- user documentation with Claude Code skill section
#     <name>[.sh]     -- main script stub (.sh for script-type, bare for docker-type)
#     [Dockerfile]    -- minimal Dockerfile stub (docker-type only)
#     [entrypoint.sh] -- container entrypoint stub (docker-type only)
#     [install.sh]    -- bundled install-stream stub (docker-type only)
#
#   agent-skills-toolbox/skills/<name>/
#     Makefile  SKILL.md  README.md  <name>[.sh]   -- (mirrored)
#
#   toolbox/Makefile  -- SCRIPT_TOOLS or DOCKER_TOOLS line patched to include <name>
#
# Requirements: bash 4+
# =============================================================================

set -euo pipefail

# -- colour helpers ------------------------------------------------------------
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { printf "${CYAN}[scaffold]${RESET}  %s\n" "$*"; }
success() { printf "${GREEN}[scaffold]${RESET}  %s\n" "$*"; }
warn()    { printf "${YELLOW}[scaffold]${RESET}  %s\n" "$*"; }
die()     { printf "${RED}[scaffold]${RESET}  ERROR: %s\n" "$*" >&2; exit 1; }
dry()     { printf "${YELLOW}[dry-run]${RESET}   %s\n" "$*"; }

# -- defaults ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLBOX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="${HOME}/Code/agent-skills-toolbox/skills"

TOOL_NAME=""
TOOL_TYPE="script"
TOOL_DESC=""
NO_MAKEFILE_PATCH=false
DRY_RUN=false

# -- usage ---------------------------------------------------------------------
usage() {
  sed -n '3,28p' "$0" | sed 's/^# \{0,2\}//'
  exit 0
}

# -- arg parsing ---------------------------------------------------------------
parse_args() {
  [[ $# -eq 0 ]] && usage

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)           usage ;;
      --type)              TOOL_TYPE="${2:?--type requires a value}"; shift 2 ;;
      --description)       TOOL_DESC="${2:?--description requires a value}"; shift 2 ;;
      --toolbox-dir)       TOOLBOX_ROOT="${2:?--toolbox-dir requires a value}"; shift 2 ;;
      --skills-dir)        SKILLS_ROOT="${2:?--skills-dir requires a value}"; shift 2 ;;
      --no-makefile-patch) NO_MAKEFILE_PATCH=true; shift ;;
      --dry-run)           DRY_RUN=true; shift ;;
      -*)                  die "Unknown option: $1" ;;
      *)
        [[ -z "$TOOL_NAME" ]] || die "Unexpected argument: $1 (tool name already set to '$TOOL_NAME')"
        TOOL_NAME="$1"; shift ;;
    esac
  done

  [[ -n "$TOOL_NAME" ]] || die "Tool name is required. Usage: scaffold-tool.sh <name> [options]"

  [[ "$TOOL_NAME" =~ ^[a-z][a-z0-9-]*$ ]] \
    || die "Tool name must be lowercase kebab-case (e.g. my-tool). Got: '$TOOL_NAME'"

  [[ "$TOOL_TYPE" == "script" || "$TOOL_TYPE" == "docker" ]] \
    || die "--type must be 'script' or 'docker'. Got: '$TOOL_TYPE'"

  [[ -n "$TOOL_DESC" ]] || TOOL_DESC="${TOOL_NAME} -- TODO: add a description"
}

# -- file writers --------------------------------------------------------------
# Each write_<kind> function takes the destination path as $1 and writes
# directly to it (no command-substitution capture, so heredoc tabs are safe).

write_makefile_script() {
  local path="$1" name="$2"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<MAKEFILE
# ============================================================
# ${name} -- Makefile
# ============================================================
.DEFAULT_GOAL := help
MAKEFLAGS     += --no-print-directory
SHELL         := /bin/bash

# -- Colors ---------------------------------------------------
BOLD   := \033[1m
GREEN  := \033[32m
CYAN   := \033[36m
RED    := \033[31m
YELLOW := \033[33m
RESET  := \033[0m

# -- Paths ----------------------------------------------------
SCRIPT  := ${name}
DESTDIR := /usr/local/bin

# -- Skill distribution ---------------------------------------
SKILL_NAME  := ${name}
SKILLS_DIR  ?= \$(HOME)/Code/agent-skills-toolbox/skills/\$(SKILL_NAME)
SKILL_FILES := \$(SCRIPT).sh SKILL.md README.md

# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^\#\#@/ { printf "\n\033[1m%s\033[0m\n", substr(\$\$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", \$\$1, \$\$2 }' \
	  \$(MAKEFILE_LIST)

##@ Install

.PHONY: install
install: ## Install ${name} to \$(DESTDIR)
	@install -m 755 \$(SCRIPT).sh \$(DESTDIR)/\$(SCRIPT).sh
	@ln -sf \$(DESTDIR)/\$(SCRIPT).sh \$(DESTDIR)/\$(SCRIPT)
	@printf "\$(GREEN)Installed\$(RESET) \$(DESTDIR)/\$(SCRIPT) -> \$(DESTDIR)/\$(SCRIPT).sh\n"

.PHONY: uninstall
uninstall: ## Remove ${name} from \$(DESTDIR)
	@rm -f \$(DESTDIR)/\$(SCRIPT) \$(DESTDIR)/\$(SCRIPT).sh
	@printf "\$(GREEN)Removed\$(RESET) \$(DESTDIR)/\$(SCRIPT)\n"

##@ Usage

.PHONY: usage
usage: ## Show ${name} usage
	@bash \$(SCRIPT).sh --help

##@ Skill distribution

.PHONY: sync-skill
sync-skill: ## Sync this repo into SKILLS_DIR (default: ~/Code/agent-skills-toolbox/skills/${name})
	@printf "\$(CYAN)Syncing to\$(RESET) \$(SKILLS_DIR)\n"
	@mkdir -p \$(SKILLS_DIR)
	@ok=0; fail=0; \\
	for f in \$(SKILL_FILES); do \\
		if /bin/cp -R \$\$f \$(SKILLS_DIR)/ 2>/dev/null; then \\
			printf "  \$(GREEN)ok\$(RESET)  \$\$f\n"; ok=\$\$((\$\$ok+1)); \\
		else \\
			printf "  \$(RED)FAIL\$(RESET)  \$\$f\n"; fail=\$\$((\$\$fail+1)); \\
		fi \\
	done; \\
	printf "\n  \$(BOLD)\$\$ok synced, \$\$fail failed\$(RESET) -> \$(SKILLS_DIR)\n"; \\
	[ \$\$fail -eq 0 ]
MAKEFILE
  success "Created $path"
}

write_makefile_docker() {
  local path="$1" name="$2"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<MAKEFILE
# ============================================================
# ${name} -- Makefile  (Docker image + ${name} wrapper)
# ============================================================
.DEFAULT_GOAL := help
MAKEFLAGS     += --no-print-directory
SHELL         := /bin/bash

# -- Colors ---------------------------------------------------
BOLD   := \033[1m
GREEN  := \033[32m
CYAN   := \033[36m
RED    := \033[31m
YELLOW := \033[33m
RESET  := \033[0m

DEBUG  := false

# -- Paths ----------------------------------------------------
TOOL_NAME        := ${name}
DESTDIR          := /usr/local/bin
TOOL_TARGET      := \$(DESTDIR)/\$(TOOL_NAME)

# -- Skill distribution ---------------------------------------
SKILL_NAME  := ${name}
SKILLS_DIR  ?= \$(HOME)/Code/agent-skills-toolbox/skills/\$(SKILL_NAME)
SKILL_FILES := \$(TOOL_NAME) SKILL.md README.md

# -- Docker ---------------------------------------------------
REGISTRY          ?= ghcr.io
IMAGE_REPO        := rondomondo/${name}
IMAGE_NAME        := \$(IMAGE_REPO)
IMAGE_TAG         ?= 0.1.0
IMAGE_SHELL       ?= bash
REMOTE_IMAGE      := \$(REGISTRY)/\$(IMAGE_REPO)
DOCKER_EXTRA_ARGS ?= --env DEBUG=\$(DEBUG) --env USE_SHELL=\$(IMAGE_SHELL)

# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^\#\#@/ { printf "\n\033[1m%s\033[0m\n", substr(\$\$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", \$\$1, \$\$2 }' \
	  \$(MAKEFILE_LIST)

##@ Install

.PHONY: install
install: ## Install ${name} to \$(DESTDIR)
	@install -m 755 \$(TOOL_NAME) \$(TOOL_TARGET)
	@printf "\$(GREEN)Installed\$(RESET) \$(TOOL_TARGET)\n"

.PHONY: uninstall
uninstall: ## Remove ${name} from \$(DESTDIR)
	@rm -f \$(TOOL_TARGET)
	@printf "\$(GREEN)Removed\$(RESET) \$(TOOL_TARGET)\n"

##@ ${name}

.PHONY: usage
usage: ## Show ${name} usage
	@bash \$(TOOL_NAME)

##@ Docker

.PHONY: docker-build
docker-build: ## Build the ${name} Docker image locally (IMAGE_TAG overridable)
	docker build --tag \$(IMAGE_NAME):\$(IMAGE_TAG) .
	\$(MAKE) docker-tag
	@printf "\$(GREEN)Built\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG)\n"

.PHONY: docker-ensure
docker-ensure: ## Pull image from ghcr.io if not present locally; fall back to local build
	@docker image inspect \$(REMOTE_IMAGE):\$(IMAGE_TAG) >/dev/null 2>&1 && \\
	  printf "\$(GREEN)Found\$(RESET) \$(REMOTE_IMAGE):\$(IMAGE_TAG) locally\n" || \\
	  { printf "\$(CYAN)Pulling\$(RESET) \$(REMOTE_IMAGE):\$(IMAGE_TAG) ...\n"; \\
	    docker pull \$(REMOTE_IMAGE):\$(IMAGE_TAG) || \\
	    { printf "\$(YELLOW)Pull failed\$(RESET) -- building locally\n"; \\
	      \$(MAKE) docker-build && \\
	      \$(MAKE) docker-tag; }; }

.PHONY: docker-shell
docker-shell: docker-ensure ## Drop into a shell in the ${name} container with \$PWD mounted at /data
	docker run --rm -it \\
	  --volume \$(PWD):/data \\
	  \$(DOCKER_EXTRA_ARGS) \\
	  \$(REMOTE_IMAGE):latest

.PHONY: docker-tag
docker-tag: ## Retag local image for REGISTRY (default ghcr.io); override with REGISTRY=docker.io or REGISTRY=local
	@if [ "\$(REGISTRY)" = "local" ]; then \\
	  printf "\$(GREEN)Local image\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG) already tagged locally\n"; \\
	  if [ "\$(IMAGE_TAG)" != "latest" ]; then \\
	    docker tag \$(IMAGE_NAME):\$(IMAGE_TAG) \$(IMAGE_NAME):latest; \\
	    printf "\$(GREEN)Tagged\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG) -> \$(IMAGE_NAME):latest\n"; \\
	  fi; \\
	else \\
	  docker tag \$(IMAGE_NAME):\$(IMAGE_TAG) \$(REMOTE_IMAGE):\$(IMAGE_TAG); \\
	  printf "\$(GREEN)Tagged\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG) -> \$(REMOTE_IMAGE):\$(IMAGE_TAG)\n"; \\
	  if [ "\$(IMAGE_TAG)" != "latest" ]; then \\
	    docker tag \$(IMAGE_NAME):\$(IMAGE_TAG) \$(REMOTE_IMAGE):latest; \\
	    printf "\$(GREEN)Tagged\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG) -> \$(REMOTE_IMAGE):latest\n"; \\
	  fi; \\
	fi

.PHONY: docker-push
docker-push: docker-tag ## Push versioned tag and :latest to REGISTRY (default ghcr.io)
	docker push \$(REMOTE_IMAGE):\$(IMAGE_TAG)
	@printf "\$(GREEN)Pushed\$(RESET) \$(REMOTE_IMAGE):\$(IMAGE_TAG)\n"
	@if [ "\$(IMAGE_TAG)" != "latest" ]; then \\
	  docker push \$(REMOTE_IMAGE):latest; \\
	  printf "\$(GREEN)Pushed\$(RESET) \$(REMOTE_IMAGE):latest\n"; \\
	fi

.PHONY: docker-release
docker-release: docker-build docker-push ## Build, tag, and push versioned + :latest to REGISTRY

.PHONY: docker-clean
docker-clean: ## Remove the local ${name} Docker image
	@docker rmi \$(IMAGE_NAME):\$(IMAGE_TAG) 2>/dev/null && \\
	  printf "\$(GREEN)Removed\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG)\n" || \\
	  printf "\$(YELLOW)Image not found\$(RESET) \$(IMAGE_NAME):\$(IMAGE_TAG)\n"

##@ Skill distribution

.PHONY: sync-skill
sync-skill: ## Sync this repo into SKILLS_DIR (default: ~/Code/agent-skills-toolbox/skills/${name})
	@printf "\$(CYAN)Syncing to\$(RESET) \$(SKILLS_DIR)\n"
	@mkdir -p \$(SKILLS_DIR)
	@ok=0; fail=0; \\
	for f in \$(SKILL_FILES); do \\
		if /bin/cp -R \$\$f \$(SKILLS_DIR)/ 2>/dev/null; then \\
			printf "  \$(GREEN)ok\$(RESET)  \$\$f\n"; ok=\$\$((\$\$ok+1)); \\
		else \\
			printf "  \$(RED)FAIL\$(RESET)  \$\$f\n"; fail=\$\$((\$\$fail+1)); \\
		fi \\
	done; \\
	printf "\n  \$(BOLD)\$\$ok synced, \$\$fail failed\$(RESET) -> \$(SKILLS_DIR)\n"; \\
	[ \$\$fail -eq 0 ]

##@ Cleanup

.PHONY: clean
clean: docker-clean ## Remove local Docker images for this project
MAKEFILE
  success "Created $path"
}

write_skill_md() {
  local path="$1" name="$2" desc="$3" type="$4"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"

  if [[ "$type" == "docker" ]]; then
    local install_block="    cp \"\$SKILL_DIR/${name}\" /usr/local/bin/${name}
    chmod +x /usr/local/bin/${name}"
    local install_local="cd ~/Code/toolbox/${name} && make install"
    local tool_check="which ${name}
docker info >/dev/null 2>&1 || echo \"ERROR: Docker is not running\""
  else
    local install_block="    cp \"\$SKILL_DIR/${name}.sh\" /usr/local/bin/${name}.sh
    chmod +x /usr/local/bin/${name}.sh
    ln -sf /usr/local/bin/${name}.sh /usr/local/bin/${name}"
    local install_local="cd ~/Code/toolbox && make -C scripts install"
    local tool_check="which ${name}"
  fi

  cat > "$path" <<SKILLMD
---
name: ${name}
description: >
    ${desc}
    Trigger on "${name}" or any request related to this tool.
---

# ${name} Skill

You are using \`${name}\` to TODO: describe what the tool does.

---

## When to use this skill

- TODO: list trigger conditions

---

## Quickstart

\`\`\`bash
# TODO: add quickstart examples
${name} --help
\`\`\`

---

## Step 0 - Resolve environment and install tool

\`\`\`bash
if [ "\${IS_SANDBOX:-no}" = "yes" ] || [ "\${IS_SANDBOX:-no}" = "1" ] || [ "\${IS_SANDBOX:-no}" = "true" ]; then
    SKILL_DIR="/mnt/skills/user/${name}"
${install_block}
else
    command -v ${name} >/dev/null 2>&1 || {
        echo "ERROR: ${name} not installed. Run: ${install_local}" >&2
        exit 1
    }
fi
\`\`\`

## Step 1 - Check for the tool

\`\`\`bash
${tool_check}
\`\`\`

If missing locally:

\`\`\`bash
${install_local}
\`\`\`

---

## Step 2 - TODO

TODO: describe inputs and usage steps.

---

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

---

## Error handling

| Symptom | Likely cause | Fix |
|---|---|---|
| \`${name} not found\` | Not installed | Run \`make install\` from \`toolbox/${name}/\` |
SKILLMD
  success "Created $path"
}

write_readme() {
  local path="$1" name="$2" desc="$3" type="$4"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"

  if [[ "$type" == "docker" ]]; then
    local req_extra="- Docker (running locally)"$'\n'
    local script_file="$name"
    local sync_files="\`${name}\`, \`SKILL.md\`, and \`README.md\`"
  else
    local req_extra=""
    local script_file="${name}.sh"
    local sync_files="\`${name}.sh\`, \`SKILL.md\`, and \`README.md\`"
  fi

  cat > "$path" <<README
# ${name}

**${desc}**

> **Also available as an [Agent Skill](#claude-code-skill)** -- install it to use \`${name}\` directly from Claude Code with no terminal required. Use the \`/${name}\` slash command or just describe what you want and your AI Agent will handle it.

---

## Quick Start

\`\`\`bash
# TODO: add quickstart examples
${name} --help
\`\`\`

---

## Installation

\`\`\`bash
# 1. Clone the toolbox repo
git clone https://github.com/rondomondo/toolbox.git && cd toolbox/${name}

# 2. Install ${name}
make install
\`\`\`

### Uninstall

\`\`\`bash
make uninstall
\`\`\`

---

## Usage

\`\`\`
${name}              Show help
${name} -h | --help  Show help
\`\`\`

---

## How it works

| File | Role |
|---|---|
| \`${script_file}\` | Main script. TODO: describe. |
| \`Makefile\` | Developer workflow: install/uninstall/sync-skill. |

---

## Makefile targets

\`\`\`
make help         Show all targets
make install      Install ${name} to /usr/local/bin
make uninstall    Remove ${name} from /usr/local/bin
make usage        Show ${name} usage
make sync-skill   Sync skill files to ~/Code/agent-skills-toolbox/skills/${name}
\`\`\`

---

## Claude Code skill

<details>
<summary>Install the <code>/${name}</code> slash command for Claude Code</summary>

This repository ships a \`/${name}\` slash command skill for [Claude Code](https://claude.ai/code)
that lets Claude use \`${name}\` -- no terminal required. Just describe what you want and
Claude will invoke the skill automatically.

### Invoking the skill

Use the slash command directly:

\`\`\`
/${name} --help
\`\`\`

Or just describe what you want in natural language -- Claude will invoke the skill automatically:

> *"TODO: add example natural language prompts"*

### Installing the skill

#### Option A -- sync locally via \`make\`

\`\`\`bash
# from inside the ${name} directory
make sync-skill
\`\`\`

This syncs ${sync_files} to:

\`\`\`
~/Code/agent-skills-toolbox/skills/${name}/
\`\`\`

Override the target directory with \`SKILLS_DIR\`:

\`\`\`bash
make sync-skill SKILLS_DIR=/path/to/your/project/.claude/skills/${name}
\`\`\`

#### Option B -- copy manually

\`\`\`bash
mkdir -p .claude/skills/${name}
cp ${script_file} SKILL.md README.md .claude/skills/${name}/
\`\`\`

</details>

---

## Requirements

${req_extra}- \`bash\` 4+
- \`make\` (for Makefile targets)
README
  success "Created $path"
}

write_script_stub() {
  local path="$1" name="$2"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<'STUB'
#!/usr/bin/env bash
# =============================================================================
# TOOL_NAME.sh
#
# TODO: describe what this script does
#
# Usage:
#   TOOL_NAME [OPTIONS]
#
# Options:
#   -h, --help    Show this help
#
# Requirements: bash 4+
# =============================================================================

set -euo pipefail

# -- colour helpers ------------------------------------------------------------
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { printf "${CYAN}[TOOL_NAME]${RESET}  %s\n" "$*"; }
ok()    { printf "${GREEN}[TOOL_NAME]${RESET}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[TOOL_NAME]${RESET}  %s\n" "$*"; }
die()   { printf "${RED}[TOOL_NAME]${RESET}  ERROR: %s\n" "$*" >&2; exit 1; }

# -- usage ---------------------------------------------------------------------
usage() {
  sed -n '3,12p' "$0" | sed 's/^# \{0,2\}//'
  exit 0
}

# -- main ----------------------------------------------------------------------
main() {
  case "${1:-}" in
    -h|--help) usage ;;
  esac

  # TODO: implement
  die "Not yet implemented"
}

main "$@"
STUB
  # Replace TOOL_NAME placeholder with actual name
  sed -i.bak "s/TOOL_NAME/${name}/g" "$path" && rm -f "${path}.bak"
  chmod +x "$path"
  success "Created $path"
}

write_docker_wrapper_stub() {
  local path="$1" name="$2"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<STUB
#!/usr/bin/env bash
# =============================================================================
# ${name}
#
# Wrapper script for the ghcr.io/rondomondo/${name} Docker image.
# TODO: describe what this tool does.
#
# Usage:
#   ${name} [OPTIONS] [ARGS...]
#   ${name} -- [args...]     Pass args directly to the container entrypoint
#
# Requirements: Docker (running locally), bash 4+
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

USE_LOGGING="\${DEBUG:-false}"
case "\${USE_LOGGING}" in
  true|1)  USE_LOGGING=true  ;;
  false|0) USE_LOGGING=false ;;
  *) printf "ERROR: DEBUG must be true/false/1/0, got '%s'\n" "\${USE_LOGGING}" >&2; exit 1 ;;
esac
SCRIPT_NAME=\$(basename "\$0")

log()  { \${USE_LOGGING} && printf "\${BOLD}[\$SCRIPT_NAME]\${RESET} \${CYAN}%s\${RESET}\n"   "\$*" >&2; return 0; }
ok()   { \${USE_LOGGING} && printf "\${BOLD}[\$SCRIPT_NAME]\${RESET} \${GREEN}%s\${RESET}\n"  "\$*" >&2; return 0; }
warn() { \${USE_LOGGING} && printf "\${BOLD}[\$SCRIPT_NAME]\${RESET} \${YELLOW}%s\${RESET}\n" "\$*" >&2; return 0; }

IMAGE="\${${name^^}_IMAGE:-ghcr.io/rondomondo/${name}:latest}"

if ! command -v docker &>/dev/null; then
  printf "\${RED}Error:\${RESET} docker is required but not found in PATH\n" >&2
  exit 1
fi

usage() {
  printf "\n\${BOLD}${name}\${RESET} -- TODO: one-line description\n\n"
  printf "Usage:\n"
  printf "  ${name} [OPTIONS]        TODO: describe\n"
  printf "  ${name} -- [args...]     Pass args directly to the container\n\n"
  printf "Environment variables:\n"
  printf "  DEBUG=true/1            Enable verbose logging\n"
  printf "  ${name^^}_IMAGE=<ref>  Override Docker image (default: \$IMAGE)\n\n"
  exit 0
}

# Stream this script to stdout when called with 'install'
if [[ "\${1:-}" == "install" ]]; then
  cat "\$0"
  exit 0
fi

case "\${1:-}" in
  -h|--help|"") usage ;;
esac

log "invoked with args '\$*'"

# TODO: implement input handling and docker run invocation
printf "\${RED}Error:\${RESET} Not yet implemented\n" >&2
exit 1
STUB
  chmod +x "$path"
  success "Created $path"
}

write_dockerfile_stub() {
  local path="$1" name="$2"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<DOCKERFILE
# ============================================================
# ${name} -- Dockerfile
# ============================================================
FROM debian:bookworm-slim

# TODO: replace base image and install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    bash \\
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY install.sh    /usr/local/bin/install.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/install.sh

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
DOCKERFILE
  success "Created $path"
}

write_entrypoint_stub() {
  local path="$1"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<'ENTRY'
#!/usr/bin/env bash
set -euo pipefail

# Stream the install.sh wrapper script to stdout
if [[ "${1:-}" == "install" ]]; then
  cat /usr/local/bin/install.sh
  exit 0
fi

# TODO: implement entrypoint logic
exec "$@"
ENTRY
  chmod +x "$path"
  success "Created $path"
}

write_install_sh_stub() {
  local path="$1" name="$2"
  if $DRY_RUN; then dry "Would write: $path"; return; fi
  mkdir -p "$(dirname "$path")"
  # install.sh IS the wrapper script -- same content as the docker wrapper stub
  cat > "$path" <<INSTALL
#!/usr/bin/env bash
# Streamed to the host via: docker run --rm ghcr.io/rondomondo/${name} install > ${name}
# This file IS the ${name} host-side wrapper script.
# TODO: replace this stub with the real wrapper (or call write_docker_wrapper_stub content).
printf "TODO: implement ${name} wrapper\n" >&2
exit 1
INSTALL
  chmod +x "$path"
  success "Created $path"
}

# -- mirror to skills dir ------------------------------------------------------
mirror_to_skills() {
  local toolbox_dir="$1" skills_dir="$2" name="$3" type="$4"
  if $DRY_RUN; then
    dry "Would mirror Makefile SKILL.md README.md + main script -> $skills_dir"
    return
  fi
  mkdir -p "$skills_dir"
  cp "$toolbox_dir/Makefile"  "$skills_dir/"
  cp "$toolbox_dir/SKILL.md"  "$skills_dir/"
  cp "$toolbox_dir/README.md" "$skills_dir/"
  if [[ "$type" == "script" ]]; then
    cp "$toolbox_dir/${name}.sh" "$skills_dir/"
  else
    cp "$toolbox_dir/${name}" "$skills_dir/"
  fi
  success "Mirrored files to $skills_dir"
}

# -- patch root Makefile -------------------------------------------------------
patch_root_makefile() {
  local root_makefile="$TOOLBOX_ROOT/Makefile" type="$1" name="$2"
  [[ -f "$root_makefile" ]] || { warn "Root Makefile not found at $root_makefile -- skipping patch"; return; }

  local var
  [[ "$type" == "script" ]] && var="SCRIPT_TOOLS" || var="DOCKER_TOOLS"

  if grep -q "\b${name}\b" "$root_makefile"; then
    info "'$name' already present in root Makefile $var line -- no patch needed"
    return
  fi

  if $DRY_RUN; then
    dry "Would patch $root_makefile: append '$name' to $var"
    return
  fi

  sed -i.bak "s/^\(${var}\s*:=.*\)$/\1 ${name}/" "$root_makefile"
  rm -f "${root_makefile}.bak"
  success "Patched $root_makefile: added '$name' to $var"
}

# -- main ----------------------------------------------------------------------
main() {
  parse_args "$@"

  local toolbox_dir="$TOOLBOX_ROOT/$TOOL_NAME"
  local skills_dir="$SKILLS_ROOT/$TOOL_NAME"

  printf "\n${BOLD}scaffold-tool${RESET}  %s  [type: %s]\n" "$TOOL_NAME" "$TOOL_TYPE"
  printf "%s\n\n" "$(printf '%0.s-' {1..50})"
  info "Toolbox dir : $toolbox_dir"
  info "Skills dir  : $skills_dir"
  info "Description : $TOOL_DESC"
  printf "\n"

  if [[ -d "$toolbox_dir" ]] && ! $DRY_RUN; then
    die "Directory already exists: $toolbox_dir\nRemove it first if you want to re-scaffold."
  fi

  # -- Makefile
  if [[ "$TOOL_TYPE" == "script" ]]; then
    write_makefile_script "$toolbox_dir/Makefile" "$TOOL_NAME"
  else
    write_makefile_docker "$toolbox_dir/Makefile" "$TOOL_NAME"
  fi

  # -- SKILL.md
  write_skill_md "$toolbox_dir/SKILL.md" "$TOOL_NAME" "$TOOL_DESC" "$TOOL_TYPE"

  # -- README.md
  write_readme "$toolbox_dir/README.md" "$TOOL_NAME" "$TOOL_DESC" "$TOOL_TYPE"

  # -- main script stub
  if [[ "$TOOL_TYPE" == "script" ]]; then
    write_script_stub "$toolbox_dir/${TOOL_NAME}.sh" "$TOOL_NAME"
  else
    write_docker_wrapper_stub "$toolbox_dir/${TOOL_NAME}" "$TOOL_NAME"
    write_dockerfile_stub     "$toolbox_dir/Dockerfile"   "$TOOL_NAME"
    write_entrypoint_stub     "$toolbox_dir/entrypoint.sh"
    write_install_sh_stub     "$toolbox_dir/install.sh"   "$TOOL_NAME"
  fi

  # -- mirror to agent-skills-toolbox
  mirror_to_skills "$toolbox_dir" "$skills_dir" "$TOOL_NAME" "$TOOL_TYPE"

  # -- patch root Makefile
  $NO_MAKEFILE_PATCH || patch_root_makefile "$TOOL_TYPE" "$TOOL_NAME"

  # -- summary
  printf "\n${GREEN}${BOLD}Done!${RESET}  Scaffolded '${TOOL_NAME}' (%s-type)\n\n" "$TOOL_TYPE"
  printf "Next steps:\n"
  if [[ "$TOOL_TYPE" == "script" ]]; then
    printf "  1. Edit ${CYAN}toolbox/${TOOL_NAME}/${TOOL_NAME}.sh${RESET}  -- implement the tool\n"
  else
    printf "  1. Edit ${CYAN}toolbox/${TOOL_NAME}/${TOOL_NAME}${RESET}     -- implement the wrapper\n"
    printf "     Edit ${CYAN}toolbox/${TOOL_NAME}/Dockerfile${RESET}       -- build the container\n"
  fi
  printf "  2. Edit ${CYAN}toolbox/${TOOL_NAME}/SKILL.md${RESET}           -- fill in agent instructions\n"
  printf "  3. Edit ${CYAN}toolbox/${TOOL_NAME}/README.md${RESET}          -- fill in user documentation\n"
  printf "\n  Run ${CYAN}make sync-skill${RESET} (from toolbox/${TOOL_NAME}/) after editing to re-sync.\n\n"
}

main "$@"
