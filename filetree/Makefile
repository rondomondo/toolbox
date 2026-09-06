# ============================================================
# filetree -- Makefile
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
SCRIPT        := filetree
DESTDIR       := /usr/local/sbin

# -- Skill distribution ---------------------------------------
SKILL_NAME  := filetree
SKILLS_DIR  ?= $(HOME)/Code/agent-skills-toolbox/skills/$(SKILL_NAME)
SKILL_FILES := $(SCRIPT).sh SKILL.md README.md

# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

# Copies filetree.sh into $(DESTDIR) and creates a symlink without the
# .sh extension so the tool is invokable as `filetree` on PATH.
.PHONY: install
install: ## Install filetree to $(DESTDIR)
	@install -m 755 $(SCRIPT).sh $(DESTDIR)/$(SCRIPT).sh
	@ln -sf $(DESTDIR)/$(SCRIPT).sh $(DESTDIR)/$(SCRIPT)
	@printf "$(GREEN)Installed$(RESET) $(DESTDIR)/$(SCRIPT) -> $(DESTDIR)/$(SCRIPT).sh\n"

# Removes both the .sh file and the extension-less symlink from $(DESTDIR).
.PHONY: uninstall
uninstall: ## Remove filetree from $(DESTDIR)
	@rm -f $(DESTDIR)/$(SCRIPT) $(DESTDIR)/$(SCRIPT).sh
	@printf "$(GREEN)Removed$(RESET) $(DESTDIR)/$(SCRIPT)\n"

##@ Usage

.PHONY: usage
usage: ## Show filetree usage
	@bash $(SCRIPT).sh --help

##@ Skill distribution

.PHONY: sync-skill
sync-skill: ## Sync this repo into SKILLS_DIR (default: ~/Code/agent-skills-toolbox/skills/filetree)
	@printf "$(CYAN)Syncing to$(RESET) $(SKILLS_DIR)\n"
	@mkdir -p $(SKILLS_DIR)
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
