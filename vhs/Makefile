# ============================================================
# vhs -- Makefile  (Docker image + vhs-rec wrapper)
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
VHS_REC        := vhs-rec
DESTDIR        := /usr/local/bin
VHS_REC_TARGET := $(DESTDIR)/$(VHS_REC)

# -- Skill distribution ---------------------------------------
SKILL_NAME  := vhs
SKILLS_DIR  ?= $(HOME)/Code/agent-skills-toolbox/skills/$(SKILL_NAME)
SKILL_FILES := $(VHS_REC) SKILL.md README.md

# -- Docker ---------------------------------------------------
REGISTRY       ?= ghcr.io
IMAGE_REPO     := rondomondo/vhs-rec
VHS_IMAGE_NAME := $(IMAGE_REPO)
VHS_IMAGE_TAG  ?= 0.1.5
VHS_IMAGE_SHELL?= zsh
REMOTE_IMAGE   := $(REGISTRY)/$(IMAGE_REPO)
DOCKER_SOCK    ?= /var/run/docker.sock
DOCKER_EXTRA_ARGS ?= --volume $(DOCKER_SOCK):$(DOCKER_SOCK) --env DOCKER_SOCK=$(DOCKER_SOCK) --env USE_SHELL=$(VHS_IMAGE_SHELL)



# -- Help -----------------------------------------------------
# Scans this Makefile for targets annotated with ## comments and prints a
# formatted usage table, grouped by ##@ section headers.
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

# Copies the vhs-rec wrapper script into $(DESTDIR) (default
# /usr/local/bin) with executable permissions so it is available on PATH.
.PHONY: install
install: ## Install vhs-rec to $(DESTDIR)
	@install -m 755 $(VHS_REC) $(VHS_REC_TARGET)
	@printf "$(GREEN)Installed$(RESET) $(VHS_REC_TARGET)\n"

# Removes the vhs-rec script from $(DESTDIR). Safe to run even if vhs-rec
# is not currently installed.
.PHONY: uninstall
uninstall: ## Remove vhs-rec from $(DESTDIR)
	@rm -f $(VHS_REC_TARGET)
	@printf "$(GREEN)Removed$(RESET) $(VHS_REC_TARGET)\n"

##@ vhs-rec

# Invokes the vhs-rec script with no arguments, which prints its built-in
# usage/help text without starting a recording or pulling an image.
.PHONY: vhs-rec-usage
vhs-rec-usage: ## Show vhs-rec usage
	@bash $(VHS_REC)

##@ Docker

# Builds the vhs-rec Docker image from the local Dockerfile and tags it as
# $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG). Override VHS_IMAGE_TAG to produce a
# different version without editing the Makefile.
.PHONY: docker-build
docker-build: ## Build the vhs-rec Docker image locally (VHS_IMAGE_TAG overridable)
	docker build --tag $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) .
	@printf "$(GREEN)Built$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG)\n"

# Checks for the image locally before pulling; if found, skips the pull.
# If the pull from ghcr.io fails (e.g. no network or auth), falls back to
# a local build followed by docker-tag so the remote tag is also set.
.PHONY: docker-ensure
docker-ensure: ## Pull image from ghcr.io if it is not present locally; fall back to local build
	@docker image inspect $(REMOTE_IMAGE):$(VHS_IMAGE_TAG) >/dev/null 2>&1 && \
	  printf "$(GREEN)Found$(RESET) $(REMOTE_IMAGE):$(VHS_IMAGE_TAG) locally\n" || \
	  { printf "$(CYAN)Pulling$(RESET) $(REMOTE_IMAGE):$(VHS_IMAGE_TAG) ...\n"; \
	    docker pull $(REMOTE_IMAGE):$(VHS_IMAGE_TAG) || \
	    { printf "$(YELLOW)Pull failed$(RESET) -- try building locally\n"; \
	    $(MAKE) docker-build && \
	    $(MAKE) docker-tag; }; }

# Runs docker-ensure to guarantee the image is available, then starts an
# interactive container with the current directory mounted at /vhs and the
# Docker socket forwarded so vhs can spawn sibling containers.
.PHONY: docker-shell
docker-shell: docker-ensure ## Drop into a zsh shell in the vhs-rec container
	docker run --rm -it \
	  --volume $(PWD):/vhs \
	  --user vhs \
	  $(DOCKER_EXTRA_ARGS) \
	  $(REMOTE_IMAGE):latest


# Retags the locally built image for the target registry. Use
# REGISTRY=local to only tag locally, REGISTRY=docker.io for Docker Hub,
# or leave unset to default to ghcr.io. Also tags :latest unless the
# version is already "latest".
.PHONY: docker-tag
docker-tag: ## Retag local image for REGISTRY (default ghcr.io); override with REGISTRY=docker.io or REGISTRY=local
	@if [ "$(REGISTRY)" = "local" ]; then \
	  printf "$(GREEN)Local image$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) already tagged locally\n"; \
	  if [ "$(VHS_IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) $(VHS_IMAGE_NAME):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) -> $(VHS_IMAGE_NAME):latest\n"; \
	  fi; \
	else \
	  docker tag $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) $(REMOTE_IMAGE):$(VHS_IMAGE_TAG); \
	  printf "$(GREEN)Tagged$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) -> $(REMOTE_IMAGE):$(VHS_IMAGE_TAG)\n"; \
	  if [ "$(VHS_IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) $(REMOTE_IMAGE):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) -> $(REMOTE_IMAGE):latest\n"; \
	  fi; \
	fi

# Pushes the versioned image to REGISTRY. Runs docker-tag first to ensure
# the remote tag exists. Also pushes :latest unless VHS_IMAGE_TAG is
# already "latest". Override REGISTRY to push to a different registry.
.PHONY: docker-push
docker-push: docker-tag ## Push versioned tag and :latest to REGISTRY (default ghcr.io); override with REGISTRY=docker.io
	docker push $(REMOTE_IMAGE):$(VHS_IMAGE_TAG)
	@printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):$(VHS_IMAGE_TAG)\n"
	@if [ "$(VHS_IMAGE_TAG)" != "latest" ]; then \
	  docker push $(REMOTE_IMAGE):latest; \
	  printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):latest\n"; \
	fi

# Convenience target that runs docker-build then docker-push in sequence,
# producing a fresh image and publishing both the versioned tag and :latest
# to REGISTRY in one step.
.PHONY: docker-release
docker-release: docker-build docker-push ## Build, tag, and push versioned + :latest to REGISTRY (default ghcr.io)

# Removes the locally tagged vhs-rec image to free disk space or force a
# clean rebuild. Prints a warning rather than failing if the image is not
# present.
.PHONY: docker-clean
docker-clean: ## Remove the local vhs-rec Docker image
	@docker rmi $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG) 2>/dev/null && \
	  printf "$(GREEN)Removed$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG)\n" || \
	  printf "$(YELLOW)Image not found$(RESET) $(VHS_IMAGE_NAME):$(VHS_IMAGE_TAG)\n"

##@ Skill distribution

.PHONY: sync-skill
sync-skill: ## Sync this repo into SKILLS_DIR (default: ~/Code/agent-skills-toolbox/skills/vhs)
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
