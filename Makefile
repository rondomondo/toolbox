# ============================================================
# toolbox -- Makefile
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
SANITISE_DIR := sanitise-ascii
ASCIINEMA_DIR := asciinema

# -- SCRIPT_TOOLS to install etc -------------------------------------
SCRIPT_TOOLS := sanitise-ascii asciinema scripts filetree

# -- DOCKER_TOOLS to install etc -------------------------------------
DOCKER_TOOLS := vhs pdf-strip cast2gif mermaid-render

# -- Help -----------------------------------------------------
# Scans the Makefile for targets annotated with ## comments and prints a
# formatted usage table, grouped by ##@ section headers.
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

.PHONY: install
install: ## Install all DOCKER_TOOLS to /usr/local/bin
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t install; done
	@for t in $(SCRIPT_TOOLS); do $(MAKE) -C $$t install; done

.PHONY: uninstall
uninstall: ## Remove all DOCKER_TOOLS from /usr/local/bin
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t uninstall; done
	@for t in $(SCRIPT_TOOLS); do $(MAKE) -C $$t uninstall; done

##@ docker stuff (delegates to */Makefile)

.PHONY: docker-build
docker-build: ## Build Docker images locally
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-build; done

.PHONY: docker-ensure
docker-ensure: ## Pull images from ghcr.io; fall back to local build
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-ensure; done

.PHONY: docker-shell
docker-shell: ## Drop into a zsh shell in the container
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-shell; done

.PHONY: docker-tag
docker-tag: ## Retag local images for REGISTRY
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-tag; done

.PHONY: docker-push
docker-push: ## Push images to REGISTRY
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-push; done

.PHONY: docker-release
docker-release: ## Build, tag, and push images
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-release; done

.PHONY: docker-clean
docker-clean: ## Remove local Docker images
	@for t in $(DOCKER_TOOLS); do $(MAKE) -C $$t docker-clean; done

##@ vhs-rec  (delegates to vhs/Makefile)

.PHONY: vhs-rec-usage
vhs-rec-usage: ## Show vhs-rec usage
	@$(MAKE) -C vhs vhs-rec-usage

##@ cast2gif  (delegates to cast2gif/Makefile)

.PHONY: cast2gif-usage
cast2gif-usage: ## Show cast2gif usage
	@$(MAKE) -C cast2gif cast2gif-usage

##@ mermaid-render  (delegates to mermaid-render/Makefile)

.PHONY: mermaid-render-usage
mermaid-render-usage: ## Show mermaid-render usage
	@$(MAKE) -C mermaid-render mermaid-render-usage

##@ pdf-strip  (delegates to pdf-strip/Makefile)

.PHONY: pdf-strip-usage
pdf-strip-usage: ## Show pdf-strip usage
	@$(MAKE) -C pdf-strip pdf-strip-usage

##@ asciinema  (delegates to asciinema/Makefile)

.PHONY: asciinema-usage
asciinema-usage: ## Show asciinema usage
	@$(MAKE) -C $(ASCIINEMA_DIR) usage

##@ Sanitise  (delegates to sanitise-ascii/Makefile)

.PHONY: sanitise-usage
sanitise-usage: ## Show sanitise-ascii usage
	@$(MAKE) -C $(SANITISE_DIR) usage

.PHONY: sanitise
sanitise: ## Run sanitise-ascii --check on all text files in this repo
	@$(MAKE) -C $(SANITISE_DIR) check SRCDIR=..

.PHONY: sanitise-fix
sanitise-fix: ## Auto-fix non-ASCII in all text files in this repo
	@$(MAKE) -C $(SANITISE_DIR) fix SRCDIR=..
