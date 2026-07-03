# =================================================================
# mermaid-render -- Makefilem(Docker image + mermaid-render wrapper)
# =================================================================
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
SKILL_NAME        := mermaid-render
DESTDIR           := /usr/local/bin
SKILL_NAME_TARGET := $(DESTDIR)/$(SKILL_NAME)

# -- Skill distribution ---------------------------------------
SKILLS_DIR            ?= $(HOME)/Code/agent-skills-toolbox/skills/$(SKILL_NAME)
SKILL_FILES           := $(SKILL_NAME) SKILL.md README.md examples references evals

# -- Docker ---------------------------------------------------
REGISTRY       ?= ghcr.io
IMAGE_REPO     := rondomondo/$(SKILL_NAME)
IMAGE_NAME     := $(IMAGE_REPO)
IMAGE_TAG      ?= 0.1.8
IMAGE_SHELL    ?= bash
REMOTE_IMAGE   := $(REGISTRY)/$(IMAGE_REPO)
DOCKER_EXTRA_ARGS ?= --env DEBUG=false --env USE_SHELL=$(IMAGE_SHELL)

# -- Test -----------------------------------------------------
TEST_INPUT     ?= examples/example1.md

# -- Help -----------------------------------------------------
.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0,5) } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' \
	  $(MAKEFILE_LIST)

##@ Install

.PHONY: install
install: ## Install mermaid-render to $(DESTDIR)
	@install -m 755 $(SKILL_NAME) $(SKILL_NAME_TARGET)
	@printf "$(GREEN)Installed$(RESET) $(SKILL_NAME_TARGET)\n"

.PHONY: uninstall
uninstall: ## Remove mermaid-render from $(DESTDIR)
	@rm -f $(SKILL_NAME_TARGET)
	@printf "$(GREEN)Removed$(RESET) $(SKILL_NAME_TARGET)\n"

##@ mermaid-render

.PHONY: mermaid-render-usage
mermaid-render-usage: ## Show mermaid-render usage
	@bash $(SKILL_NAME)

.PHONY: test
test: ## Render TEST_INPUT as SVG and PNG to verify the full pipeline (override: TEST_INPUT=examples/foo.md)
	@printf "$(BOLD)$(CYAN)--- SVG render ---$(RESET)\n"
	@bash $(SKILL_NAME) $(TEST_INPUT) --scale 2 -f svg
	@printf "$(BOLD)$(CYAN)--- PNG render ---$(RESET)\n"
	@bash $(SKILL_NAME) $(TEST_INPUT) --scale 2 -f png --width 960 --height 640
	@printf "$(GREEN)Test renders complete$(RESET)\n"

.PHONY: clean
clean: ## Remove rendered output files from examples/ and data/
	@printf "$(CYAN)Removing$(RESET) rendered output files...\n"
	@find examples/ -maxdepth 1 -type f \( -name "*.svg.md" -o -name "*.png.md" -o -name "*.pdf.md" -o -name "*.webp.md" -o -name "*.gif.md" -o -name "*.jpg.md" -o -name "*.md-[0-9]*.svg" -o -name "*.md-[0-9]*.png" -o -name "*.md-[0-9]*.pdf" -o -name "*.md-[0-9]*.webp" -o -name "*.md-[0-9]*.gif" -o -name "*.md-[0-9]*.jpg" \) -delete 2>/dev/null || true
	@printf "$(GREEN)Clean$(RESET)\n"

.PHONY: check
check: ## Verify mermaid-render is installed and reachable
	@command -v mermaid-render >/dev/null 2>&1 \
	  && printf "$(GREEN)OK$(RESET)  mermaid-render found at $$(command -v mermaid-render)\n" \
	  || { printf "$(RED)FAIL$(RESET)  mermaid-render not found in PATH -- run: make install\n"; exit 1; }

##@ Docker

.PHONY: docker-build
docker-build: ## Build the mermaid-render Docker image locally (IMAGE_TAG overridable)
	docker build --tag $(IMAGE_NAME):$(IMAGE_TAG) .
	@printf "$(GREEN)Built$(RESET) $(IMAGE_NAME):$(IMAGE_TAG)\n"

.PHONY: docker-ensure
docker-ensure: ## Pull image from ghcr.io if not present locally; fall back to local build
	@docker image inspect $(REMOTE_IMAGE):$(IMAGE_TAG) >/dev/null 2>&1 && \
	  printf "$(GREEN)Found$(RESET) $(REMOTE_IMAGE):$(IMAGE_TAG) locally\n" || \
	  { printf "$(CYAN)Pulling$(RESET) $(REMOTE_IMAGE):$(IMAGE_TAG) ...\n"; \
	    docker pull $(REMOTE_IMAGE):$(IMAGE_TAG) || \
	    { printf "$(YELLOW)Pull failed$(RESET) -- try building locally\n"; \
	    $(MAKE) docker-build && \
	    $(MAKE) docker-tag; }; }

.PHONY: docker-shell
docker-shell: docker-ensure ## Drop into a bash shell in the mermaid-render container
	docker run --rm -it \
	  --volume $(PWD):/data \
	  --user mermaidcli \
	  $(DOCKER_EXTRA_ARGS) \
	  $(REMOTE_IMAGE):latest

.PHONY: docker-tag
docker-tag: ## Retag local image for REGISTRY (default ghcr.io); override with REGISTRY=docker.io or REGISTRY=local
	@if [ "$(REGISTRY)" = "local" ]; then \
	  printf "$(GREEN)Local image$(RESET) $(IMAGE_NAME):$(IMAGE_TAG) already tagged locally\n"; \
	  if [ "$(IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(IMAGE_NAME):$(IMAGE_TAG) -> $(IMAGE_NAME):latest\n"; \
	  fi; \
	else \
	  docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REMOTE_IMAGE):$(IMAGE_TAG); \
	  printf "$(GREEN)Tagged$(RESET) $(IMAGE_NAME):$(IMAGE_TAG) -> $(REMOTE_IMAGE):$(IMAGE_TAG)\n"; \
	  if [ "$(IMAGE_TAG)" != "latest" ]; then \
	    docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REMOTE_IMAGE):latest; \
	    printf "$(GREEN)Tagged$(RESET) $(IMAGE_NAME):$(IMAGE_TAG) -> $(REMOTE_IMAGE):latest\n"; \
	  fi; \
	fi

.PHONY: docker-push
docker-push: docker-tag ## Push versioned tag and :latest to REGISTRY (default ghcr.io)
	docker push $(REMOTE_IMAGE):$(IMAGE_TAG)
	@printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):$(IMAGE_TAG)\n"
	@if [ "$(IMAGE_TAG)" != "latest" ]; then \
	  docker push $(REMOTE_IMAGE):latest; \
	  printf "$(GREEN)Pushed$(RESET) $(REMOTE_IMAGE):latest\n"; \
	fi

.PHONY: docker-release
docker-release: docker-build docker-push ## Build, tag, and push versioned + :latest to REGISTRY

.PHONY: docker-clean
docker-clean: ## Remove the local mermaid-render Docker image
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null && \
	  printf "$(GREEN)Removed$(RESET) $(IMAGE_NAME):$(IMAGE_TAG)\n" || \
	  printf "$(YELLOW)Image not found$(RESET) $(IMAGE_NAME):$(IMAGE_TAG)\n"

##@ Image management

.PHONY: pull-image
pull-image: ## Pre-pull the mermaid-render Docker image
	@printf "$(CYAN)Pulling$(RESET) ghcr.io/$(IMAGE_REPO):latest...\n"
	@docker pull ghcr.io/$(IMAGE_REPO):latest
	@printf "$(GREEN)Image ready$(RESET)\n"

##@ Skill distribution

.PHONY: sync-skill
sync-skill: ## Sync this repo into SKILLS_DIR (default: ~/Code/agent-skills-toolbox/skills/mermaid-render)
	@printf "$(CYAN)Syncing to$(RESET) $(SKILLS_DIR)\n"
	@mkdir -p $(SKILLS_DIR)/examples $(SKILLS_DIR)/references
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

##@ Legacy

.PHONY: doctor
doctor: ## Show environment info useful for bug reports
	@printf "$(BOLD)$(SKILL_NAME) doctor$(RESET)\n\n"
	@printf "  Shell:         %s\n" "$$SHELL"
	@printf "  Wrapper:       "; ls -lh "$(SKILL_NAME)" 2>/dev/null || printf "$(RED)not found$(RESET)\n"
	@printf "  Docker:        "; docker --version 2>/dev/null || printf "$(RED)not found$(RESET)\n"
	@printf "  Docker running: "; docker info >/dev/null 2>&1 && printf "$(GREEN)yes$(RESET)\n" || printf "$(RED)no$(RESET)\n"
	@printf "  $(SKILL_NAME) image: "; docker image inspect $(REMOTE_IMAGE):latest --format '{{.RepoTags}} ({{.Id}})' 2>/dev/null || printf "not pulled\n"
	@echo ""
