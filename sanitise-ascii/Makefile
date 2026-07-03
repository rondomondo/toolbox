# ============================================================
# sanitise-ascii -- Makefile
# ============================================================
.DEFAULT_GOAL := help
MAKEFLAGS     += --no-print-directory
SHELL         := /bin/bash

# -- Colors ---------------------------------------------------
BOLD   := \033[1m
GREEN  := \033[32m
CYAN   := \033[36m
YELLOW := \033[33m
RESET  := \033[0m

# -- Paths ----------------------------------------------------
SANITISE      := sanitise-ascii
DESTDIR       := /usr/local/bin
SRCDIR        ?= .

# -- Skill distribution ---------------------------------------
SKILL_NAME    := sanitise-ascii
SKILLS_DIR    ?= $(HOME)/Code/agent-skills-toolbox/skills/sanitise-ascii
SKILL_FILES   := $(SANITISE).py SKILL.md README.md

# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

# Copies sanitise-ascii.py into $(DESTDIR) and creates a symlink without the
# .py extension so the tool is invokable as `sanitise-ascii` on PATH.
.PHONY: install
install: ## Install sanitise-ascii to $(DESTDIR)
	@install -m 755 $(SANITISE).py $(DESTDIR)/$(SANITISE).py
	@ln -sf $(DESTDIR)/$(SANITISE).py $(DESTDIR)/$(SANITISE)
	@printf "$(GREEN)Installed$(RESET) $(DESTDIR)/$(SANITISE) -> $(DESTDIR)/$(SANITISE).py\n"

# Removes both the .py file and the extension-less symlink from $(DESTDIR).
.PHONY: uninstall
uninstall: ## Remove sanitise-ascii from $(DESTDIR)
	@rm -f $(DESTDIR)/$(SANITISE) $(DESTDIR)/$(SANITISE).py
	@printf "$(GREEN)Removed$(RESET) $(DESTDIR)/$(SANITISE)\n"

##@ Sanitise

# Invokes sanitise-ascii with --help, printing the full usage text that
# describes flags, supported file types, and exit codes.
.PHONY: usage
usage: ## Show sanitise-ascii usage
	@uv run python3 $(SANITISE).py --help

# Runs sanitise-ascii in check (dry-run) mode across all common text files
# in the repo root, reporting non-ASCII characters without modifying any files.
# Exits 1 if any non-ASCII characters are found.
.PHONY: check
check: ## Run sanitise-ascii --check on all text files in the repo root (default - no writes)
	@uv run python3 $(SANITISE).py --check --dir $(SRCDIR)

# Runs sanitise-ascii in fix mode, replacing known non-ASCII characters with
# ASCII equivalents in place. Characters not in the fix map are reported as
# WARNs and left for manual review; exits 1 if any remain after fixing.
.PHONY: fix
fix: ## Auto-fix non-ASCII in all text files in the repo root
	@uv run python3 $(SANITISE).py --fix --dir $(SRCDIR)

##@ Skill distribution

.PHONY: sync-skill
sync-skill: ## Sync this repo into SKILLS_DIR (default: ~/Code/agent-skills-toolbox/skills/sanitise-ascii)
	@printf "$(CYAN)Syncing to$(RESET) $(SKILLS_DIR)\n"
	@ok=0; fail=0; \
	for f in $(SKILL_FILES); do \
		if /bin/cp -R $$f $(SKILLS_DIR)/ 2>/dev/null; then \
			printf "  $(GREEN)ok$(RESET)  $$f\n"; ok=$$((ok+1)); \
		else \
			printf "  $(RED)FAIL$(RESET)  $$f\n"; fail=$$((fail+1)); \
		fi \
	done; \
	printf "\n  $(BOLD)$$ok synced, $$fail failed$(RESET) -> $(SKILLS_DIR)\n"; \
	[ $$fail -eq 0 ]

