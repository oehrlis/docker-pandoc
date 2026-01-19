.PHONY: help build build-multi push test test-samples lint lint-shell lint-shell-format lint-markdown lint-docker release version clean shell

# Variables
IMAGE_NAME := oehrlis/pandoc
VERSION := $(shell cat VERSION 2>/dev/null || echo "dev")
DOCKER_REGISTRY := docker.io
PLATFORMS := linux/amd64,linux/arm64
DOCKER_USER := oehrlis
BUILD_CONTEXT := $(shell pwd)

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(BLUE)Pandoc Docker Image - Makefile Help$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(GREEN)<target>$(NC)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build Targets

build: ## Build Docker image locally (single platform)
	@echo "$(BLUE)Building $(IMAGE_NAME):$(VERSION) locally...$(NC)"
	./scripts/build.sh $(VERSION) --local
	@echo "$(BLUE)Testing sample documents...$(NC)"
	./scripts/test.sh $(VERSION)

build-multi: ## Build multi-platform image and push to registry
	@echo "$(BLUE)Building and pushing multi-platform $(IMAGE_NAME):$(VERSION)...$(NC)"
	@docker buildx create --use --name multi-builder 2>/dev/null || docker buildx use multi-builder
	@docker buildx build \
		--platform $(PLATFORMS) \
		--build-arg SLIM_TEX=1 \
		--build-arg PRUNE_MS_FONTS=1 \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		-t $(IMAGE_NAME):texlive-slim \
		--push \
		.
	@echo "$(GREEN)Multi-platform build and push completed$(NC)"

push: ## Push image to Docker Hub
	@echo "$(BLUE)Building and pushing $(IMAGE_NAME):$(VERSION) to Docker Hub...$(NC)"
	./scripts/build.sh $(VERSION) --push
	@echo "$(GREEN)Image pushed successfully$(NC)"

##@ Testing Targets

test: test-samples ## Run all tests (build samples, validate examples)

test-samples: ## Build all sample documents to verify functionality
	@echo "$(BLUE)Building sample documents...$(NC)"
	./scripts/test.sh $(VERSION)
	@echo "$(GREEN)Sample documents built successfully$(NC)"

##@ Linting Targets

lint: lint-shell lint-shell-format lint-markdown lint-docker ## Run all linting checks

lint-shell: ## Run shellcheck on all shell scripts
	@echo "$(BLUE)Running shellcheck...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh; \
		echo "$(GREEN)Shellcheck passed$(NC)"; \
	else \
		echo "$(YELLOW)shellcheck not installed. Install with: apt-get install shellcheck$(NC)"; \
		exit 1; \
	fi

lint-shell-format: ## Run shfmt on all shell scripts
	@echo "$(BLUE)Running shfmt...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -d -i 2 -ci scripts/*.sh; \
		echo "$(GREEN)Shell format check passed$(NC)"; \
	else \
		echo "$(YELLOW)shfmt not installed. Install from: https://github.com/mvdan/sh/releases$(NC)"; \
		exit 1; \
	fi

lint-markdown: ## Run markdownlint on all markdown files
	@echo "$(BLUE)Running markdownlint...$(NC)"
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint README.md CHANGELOG.md scripts/README.md examples/*.md || true; \
		echo "$(GREEN)Markdown lint completed$(NC)"; \
	elif command -v docker >/dev/null 2>&1; then \
		docker run --rm -v $(BUILD_CONTEXT):/workdir:z \
			davidanson/markdownlint-cli2:v0.10.0 \
			README.md CHANGELOG.md scripts/README.md examples/*.md; \
		echo "$(GREEN)Markdown lint completed (via Docker)$(NC)"; \
	else \
		echo "$(YELLOW)markdownlint not installed. Install with: npm install -g markdownlint-cli$(NC)"; \
		echo "$(YELLOW)Or use Docker: docker run --rm -v \$$PWD:/workdir:z davidanson/markdownlint-cli2:v0.10.0 <files>$(NC)"; \
		exit 1; \
	fi

lint-docker: ## Run hadolint on Dockerfile
	@echo "$(BLUE)Running hadolint...$(NC)"
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint Dockerfile; \
		echo "$(GREEN)Dockerfile lint passed$(NC)"; \
	else \
		echo "$(YELLOW)hadolint not installed (optional). Install from: https://github.com/hadolint/hadolint/releases$(NC)"; \
	fi

##@ Release Targets

release: ## Release with version bump (usage: make release [RELEASE_TYPE=patch|minor|major])
	@echo "$(BLUE)Running release script...$(NC)"
	./scripts/release.sh $(RELEASE_TYPE)
	@echo "$(GREEN)Release completed$(NC)"

version: ## Display current version from VERSION file
	@echo "Current version: $(VERSION)"

##@ Utility Targets

clean: ## Clean up build artifacts
	@echo "$(BLUE)Cleaning up build artifacts...$(NC)"
	@rm -f sample/sample-test.pdf sample/sample-test.docx sample/sample-test.pptx
	@rm -f sample/sample-release.pdf sample/sample-release.docx sample/sample-release.pptx
	@rm -f examples/test-mermaid-test.pdf examples/test-mermaid-release.pdf
	@rm -f examples/test-output.pdf
	@echo "$(GREEN)Cleanup completed$(NC)"

shell: ## Open interactive shell in container
	@echo "$(BLUE)Opening shell in $(IMAGE_NAME):$(VERSION)...$(NC)"
	@docker run -it --rm -v $(BUILD_CONTEXT):/workdir:z --entrypoint sh $(IMAGE_NAME):$(VERSION)
