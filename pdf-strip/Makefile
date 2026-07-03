# ============================================================
# pdf-strip -- Makefile
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

# -- Install --------------------------------------------------
PDF_STRIP        := pdf-strip
DESTDIR          := /usr/local/bin
PDF_STRIP_TARGET := $(DESTDIR)/$(PDF_STRIP)

# -- Docker ---------------------------------------------------
REGISTRY           ?= ghcr.io
IMAGE_REPO         := rondomondo/pdf-strip
PDF_STRIP_IMAGE_SHELL ?= bash
PDF_STRIP_IMAGE_NAME ?= $(IMAGE_REPO)
PDF_STRIP_IMAGE_TAG  ?= 0.1.5
REMOTE_IMAGE      := $(REGISTRY)/$(IMAGE_REPO)
DOCKER_EXTRA_ARGS    ?= --env DEBUG=$(DEBUG) --env USE_SHELL=$(PDF_STRIP_IMAGE_SHELL)

TEST_PDF := $(CURDIR)/test/example.pdf

# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

.PHONY: install
install: ## Install pdf-strip script to $(DESTDIR)
	@install -m 755 $(PDF_STRIP) $(PDF_STRIP_TARGET)
	@printf "$(GREEN)Installed$(RESET) $(PDF_STRIP_TARGET)\n"

.PHONY: uninstall
uninstall: ## Remove pdf-strip from $(DESTDIR)
	@rm -f $(PDF_STRIP_TARGET)
	@printf "$(GREEN)Removed$(RESET) $(PDF_STRIP_TARGET)\n"

##@ pdf-strip

.PHONY: pdf-strip-usage
pdf-strip-usage: ## Show pdf-strip script usage
	@bash $(PDF_STRIP) --help

##@ Docker

.PHONY: docker-build
docker-build: ## Build the pdf-strip Docker image locally (PDF_STRIP_IMAGE_TAG overridable)
	docker build --tag $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) .
	$(MAKE) docker-tag
	@printf "$(GREEN)Built$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG)\n"

.PHONY: docker-ensure
docker-ensure: ## Pull image from ghcr.io if not present locally; fall back to local build
	@docker image inspect $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG) >/dev/null 2>&1 && \
	  printf "$(GREEN)Found$(RESET) $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG) locally\n" || \
	  { printf "$(CYAN)Pulling$(RESET) $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG) ...\n"; \
	    docker pull $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG) || \
	    { printf "$(YELLOW)Pull failed$(RESET) -- building locally\n"; \
	      $(MAKE) docker-build && \
	      $(MAKE) docker-tag; }; }

.PHONY: docker-shell
docker-shell: docker-ensure ## Drop into a shell in the pdf-strip container with $PWD mounted at /data
	docker run --rm -it \
	  --volume $(PWD):/data \
	  $(DOCKER_EXTRA_ARGS) \
	  $(REMOTE_IMAGE):latest

.PHONY: docker-tag
docker-tag: ## Retag local image for REGISTRY (default ghcr.io); override with REGISTRY=docker.io or REGISTRY=local
	@if [ "$(REGISTRY)" = "local" ]; then \
	  printf "$(GREEN)Local image$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) already tagged locally\n"; \
	  if [ "$(PDF_STRIP_IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) $(PDF_STRIP_IMAGE_NAME):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) -> $(PDF_STRIP_IMAGE_NAME):latest\n"; \
	  fi; \
	else \
	  docker tag $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG); \
	  printf "$(GREEN)Tagged$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) -> $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG)\n"; \
	  if [ "$(PDF_STRIP_IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) $(REMOTE_IMAGE):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) -> $(REMOTE_IMAGE):latest\n"; \
	  fi; \
	fi

.PHONY: docker-push
docker-push: docker-tag ## Push versioned tag and :latest to REGISTRY (default ghcr.io)
	docker push $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG)
	@printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG)\n"
	@if [ "$(PDF_STRIP_IMAGE_TAG)" != "latest" ]; then \
	  docker push $(REMOTE_IMAGE):latest; \
	  printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):latest\n"; \
	fi

.PHONY: docker-release
docker-release: docker-build docker-push ## Build, tag, and push versioned + :latest to REGISTRY

.PHONY: docker-clean
docker-clean: ## Remove the local pdf-strip Docker image
	@docker rmi $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG) 2>/dev/null && \
	  printf "$(GREEN)Removed$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG)\n" || \
	  printf "$(YELLOW)Image not found$(RESET) $(PDF_STRIP_IMAGE_NAME):$(PDF_STRIP_IMAGE_TAG)\n"

##@ Usage

.PHONY: usage
usage: ## Print usage examples
	@printf "\n$(BOLD)pdf-strip$(RESET) -- Docker-based PDF metadata stripper\n"
	@printf "Image: $(CYAN)$(REMOTE_IMAGE):$(PDF_STRIP_IMAGE_TAG)$(RESET)\n\n"
	@printf "$(BOLD)Strip all PDFs in a directory:$(RESET)\n"
	@printf "  pdf-strip /path/to/dir\n"
	@printf "  docker run --rm -v /your/pdfs:/data $(REMOTE_IMAGE):latest\n\n"
	@printf "$(BOLD)Strip one or more files:$(RESET)\n"
	@printf "  pdf-strip file.pdf\n"
	@printf "  pdf-strip file1.pdf file2.pdf\n\n"
	@printf "$(BOLD)Check PDFs for metadata (no stripping):$(RESET)\n"
	@printf "  pdf-strip --check file.pdf\n"
	@printf "  pdf-strip --check /path/to/dir\n\n"
	@printf "$(BOLD)Install pdf-strip script:$(RESET)\n"
	@printf "  make install\n\n"

##@ Cleanup

.PHONY: clean
clean: docker-clean ## Remove local Docker images for this project
