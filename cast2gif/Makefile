# ============================================================
# cast2gif -- Makefile  (Docker image + cast2gif wrapper)
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

DEBUG  := false

# -- Paths ----------------------------------------------------
CAST2GIF        := cast2gif
DESTDIR         := /usr/local/bin
CAST2GIF_TARGET := $(DESTDIR)/$(CAST2GIF)

# -- Docker ---------------------------------------------------
REGISTRY          ?= ghcr.io
IMAGE_REPO        := rondomondo/cast2gif
AGG_IMAGE_NAME    := $(IMAGE_REPO)
AGG_IMAGE_TAG     ?= 0.1.5
AGG_IMAGE_SHELL   ?= zsh
REMOTE_IMAGE      := $(REGISTRY)/$(IMAGE_REPO)
DOCKER_EXTRA_ARGS ?= --env DEBUG=$(DEBUG) --env USE_SHELL=$(AGG_IMAGE_SHELL)


# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

.PHONY: install
install: ## Install cast2gif to $(DESTDIR)
	@install -m 755 $(CAST2GIF) $(CAST2GIF_TARGET)
	@printf "$(GREEN)Installed$(RESET) $(CAST2GIF_TARGET)\n"

.PHONY: uninstall
uninstall: ## Remove cast2gif from $(DESTDIR)
	@rm -f $(CAST2GIF_TARGET)
	@printf "$(GREEN)Removed$(RESET) $(CAST2GIF_TARGET)\n"

##@ cast2gif

.PHONY: cast2gif-usage
cast2gif-usage: ## Show cast2gif usage
	@bash $(CAST2GIF)

##@ Docker

.PHONY: docker-build
docker-build: ## Build the cast2gif Docker image locally (AGG_IMAGE_TAG overridable)
	docker build --tag $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) .
	$(MAKE) docker-tag
	@printf "$(GREEN)Built$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG)\n"

.PHONY: docker-ensure
docker-ensure: ## Pull image from ghcr.io if not present locally; fall back to local build
	@docker image inspect $(REMOTE_IMAGE):$(AGG_IMAGE_TAG) >/dev/null 2>&1 && \
	  printf "$(GREEN)Found$(RESET) $(REMOTE_IMAGE):$(AGG_IMAGE_TAG) locally\n" || \
	  { printf "$(CYAN)Pulling$(RESET) $(REMOTE_IMAGE):$(AGG_IMAGE_TAG) ...\n"; \
	    docker pull $(REMOTE_IMAGE):$(AGG_IMAGE_TAG) || \
	    { printf "$(YELLOW)Pull failed$(RESET) -- building locally\n"; \
	      $(MAKE) docker-build && \
	      $(MAKE) docker-tag; }; }

.PHONY: docker-shell
docker-shell: docker-ensure ## Drop into a shell in the cast2gif container with $PWD mounted at /data
	docker run --rm -it \
	  --volume $(PWD):/data \
	  $(DOCKER_EXTRA_ARGS) \
	  $(REMOTE_IMAGE):latest

.PHONY: docker-tag
docker-tag: ## Retag local image for REGISTRY (default ghcr.io); override with REGISTRY=docker.io or REGISTRY=local
	@if [ "$(REGISTRY)" = "local" ]; then \
	  printf "$(GREEN)Local image$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) already tagged locally\n"; \
	  if [ "$(AGG_IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) $(AGG_IMAGE_NAME):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) -> $(AGG_IMAGE_NAME):latest\n"; \
	  fi; \
	else \
	  docker tag $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) $(REMOTE_IMAGE):$(AGG_IMAGE_TAG); \
	  printf "$(GREEN)Tagged$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) -> $(REMOTE_IMAGE):$(AGG_IMAGE_TAG)\n"; \
	  if [ "$(AGG_IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) $(REMOTE_IMAGE):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) -> $(REMOTE_IMAGE):latest\n"; \
	  fi; \
	fi

.PHONY: docker-push
docker-push: docker-tag ## Push versioned tag and :latest to REGISTRY (default ghcr.io)
	docker push $(REMOTE_IMAGE):$(AGG_IMAGE_TAG)
	@printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):$(AGG_IMAGE_TAG)\n"
	@if [ "$(AGG_IMAGE_TAG)" != "latest" ]; then \
	  docker push $(REMOTE_IMAGE):latest; \
	  printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):latest\n"; \
	fi

.PHONY: docker-release
docker-release: docker-build docker-push ## Build, tag, and push versioned + :latest to REGISTRY

.PHONY: docker-clean
docker-clean: ## Remove the local cast2gif Docker image
	@docker rmi $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG) 2>/dev/null && \
	  printf "$(GREEN)Removed$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG)\n" || \
	  printf "$(YELLOW)Image not found$(RESET) $(AGG_IMAGE_NAME):$(AGG_IMAGE_TAG)\n"
