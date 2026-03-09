# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Makefile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-03-09
# Revision...: 4.0.0
# Purpose....: Docker Pandoc image workflow automation.
#              Provides targets for building variants, testing, version
#              management, and multi-platform release.
# Notes......: Use 'make help' to show available targets and release workflow
# Reference..: https://github.com/oehrlis/docker-pandoc
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Ensure Homebrew-installed tools are found regardless of caller's PATH
PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)
export PATH

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
IMAGE_NAME   := oehrlis/pandoc
VERSION      := $(shell cat VERSION 2>/dev/null || echo "0.0.0")
VARIANT      ?= standard
PLATFORMS    := linux/amd64,linux/arm64
BUILDER      := multi-builder
SCRIPT_DIR   := scripts
SAMPLE_DIR   := sample

GIT          := $(shell PATH="$(PATH)" command -v git        2>/dev/null)
SHELLCHECK   := $(shell PATH="$(PATH)" command -v shellcheck 2>/dev/null)
SHFMT        := $(shell PATH="$(PATH)" command -v shfmt      2>/dev/null)
MARKDOWNLINT := $(shell PATH="$(PATH)" command -v markdownlint 2>/dev/null || \
                        PATH="$(PATH)" command -v markdownlint-cli 2>/dev/null)
HADOLINT     := $(shell PATH="$(PATH)" command -v hadolint   2>/dev/null)

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
.PHONY: help
help: ## Show available targets and release workflow
	@echo "docker-pandoc Makefile — image build & release workflow"
	@echo ""
	@echo "Release workflow:"
	@echo "  Patch release : make release                      # bump patch → commit → tag"
	@echo "  Minor release : make version-bump-minor && make tag"
	@echo "  Major release : make version-bump-major && make tag"
	@echo "  Tag only      : make tag                          # tag current committed VERSION"
	@echo "  After tag     : git push origin master && git push origin v<VERSION>"
	@echo ""
	@echo "Build workflow:"
	@echo "  Single variant: make build [VARIANT=minimal|standard|mermaid|full]"
	@echo "  All variants  : make build-all"
	@echo "  Multi-platform: make build-multi  (pushes to registry)"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-26s %s\n", $$1, $$2}'

# ------------------------------------------------------------------------------
# Build targets
# ------------------------------------------------------------------------------
.PHONY: build
build: ## Build single variant locally (VARIANT=standard|minimal|mermaid|full)
	@echo "==> Building $(IMAGE_NAME):dev-$(VARIANT) locally"
	docker buildx build \
		--build-arg IMAGE_VARIANT=$(VARIANT) \
		-t $(IMAGE_NAME):dev-$(VARIANT) \
		--load .
	@echo "==> Done: $(IMAGE_NAME):dev-$(VARIANT)"

.PHONY: build-all
build-all: ## Build all four variants locally
	@for v in minimal standard mermaid full; do \
		echo "==> Building variant: $$v"; \
		docker buildx build --build-arg IMAGE_VARIANT=$$v \
			-t $(IMAGE_NAME):dev-$$v --load . || exit 1; \
	done
	@echo "==> All variants built"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
		grep -E "(REPOSITORY|dev-)" || true

.PHONY: build-release
build-release: ## Build all variants locally with VERSION tags (no push)
	@echo "==> Building release $(VERSION) — tag strategy:"
	@echo "    VERSION-VARIANT  all four variants"
	@echo "    VERSION          → standard"
	@echo "    latest           → standard"
	@for v in minimal standard mermaid full; do \
		echo "==> Building $(IMAGE_NAME):$(VERSION)-$$v"; \
		extra=""; \
		if [ "$$v" = "standard" ]; then \
			extra="-t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest"; \
		fi; \
		docker buildx build --build-arg IMAGE_VARIANT=$$v \
			-t $(IMAGE_NAME):$(VERSION)-$$v $$extra --load . || exit 1; \
	done
	@echo "==> Done. Images:"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
		grep -E "(REPOSITORY|$(VERSION)|latest)" || true

.PHONY: build-multi
build-multi: ## Build all variants multi-platform and push to registry
	@echo "==> Multi-platform build and push: $(PLATFORMS)"
	@echo "    Tag strategy:"
	@echo "    VERSION-VARIANT  all four variants"
	@echo "    VERSION          → standard"
	@echo "    latest           → standard"
	@docker buildx create --use --name $(BUILDER) 2>/dev/null || \
		docker buildx use $(BUILDER)
	@for v in minimal standard mermaid full; do \
		echo "==> Pushing $(IMAGE_NAME):$(VERSION)-$$v ($(PLATFORMS))"; \
		extra=""; \
		if [ "$$v" = "standard" ]; then \
			extra="--tag $(IMAGE_NAME):$(VERSION) --tag $(IMAGE_NAME):latest"; \
		fi; \
		docker buildx build \
			--platform $(PLATFORMS) \
			--build-arg IMAGE_VARIANT=$$v \
			--tag $(IMAGE_NAME):$(VERSION)-$$v \
			$$extra \
			--push . || exit 1; \
	done
	@echo "==> Multi-platform push complete: $(VERSION)"

# ------------------------------------------------------------------------------
# Test targets
# ------------------------------------------------------------------------------
.PHONY: test
test: ## Test a locally built variant (VARIANT=standard|minimal|mermaid|full)
	@$(SCRIPT_DIR)/test.sh dev-$(VARIANT)

.PHONY: test-all
test-all: ## Test all locally built variants
	@for v in minimal standard mermaid full; do \
		echo "==> Testing dev-$$v"; \
		$(SCRIPT_DIR)/test.sh dev-$$v || exit 1; \
	done

# ------------------------------------------------------------------------------
# Lint targets
# ------------------------------------------------------------------------------
.PHONY: lint
lint: lint-shell lint-markdown lint-docker ## Run all linting checks

.PHONY: lint-shell
lint-shell: ## Lint shell scripts with shellcheck
	@if [[ -z "$(SHELLCHECK)" ]]; then \
		echo "Error: shellcheck not found (install: brew install shellcheck)"; exit 1; \
	fi
	@find $(SCRIPT_DIR) -type f -name "*.sh" -print0 | \
		xargs -0 "$(SHELLCHECK)" -x -S warning
	@echo "==> shellcheck passed"

.PHONY: fmt-shell
fmt-shell: ## Check shell script formatting with shfmt (diff only)
	@if [[ -z "$(SHFMT)" ]]; then \
		echo "Error: shfmt not found (install: brew install shfmt)"; exit 1; \
	fi
	@find $(SCRIPT_DIR) -type f -name "*.sh" -print0 | \
		xargs -0 "$(SHFMT)" -d -i 4 -bn -ci -sr
	@echo "==> shfmt check passed"

.PHONY: fmt-shell-write
fmt-shell-write: ## Format shell scripts in-place with shfmt
	@if [[ -z "$(SHFMT)" ]]; then \
		echo "Error: shfmt not found (install: brew install shfmt)"; exit 1; \
	fi
	@find $(SCRIPT_DIR) -type f -name "*.sh" -print0 | \
		xargs -0 "$(SHFMT)" -w -i 4 -bn -ci -sr
	@echo "==> Shell scripts formatted"

.PHONY: lint-markdown
lint-markdown: ## Lint markdown files with markdownlint
	@if [[ -z "$(MARKDOWNLINT)" ]]; then \
		echo "Error: markdownlint not found (install: npm install -g markdownlint-cli)"; exit 1; \
	fi
	@"$(MARKDOWNLINT)" --config .markdownlint.yaml "**/*.md" 2>/dev/null || \
		"$(MARKDOWNLINT)" "**/*.md"

.PHONY: lint-docker
lint-docker: ## Lint Dockerfile with hadolint
	@if [[ -z "$(HADOLINT)" ]]; then \
		echo "    hadolint not installed (optional) — skipping"; \
	else \
		"$(HADOLINT)" Dockerfile && echo "==> hadolint passed"; \
	fi

# ------------------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------------------
.PHONY: clean
clean: ## Remove generated test artefacts
	@rm -f $(SAMPLE_DIR)/sample-test.pdf  $(SAMPLE_DIR)/sample-test.docx  \
	        $(SAMPLE_DIR)/sample-test.pptx
	@rm -f $(SAMPLE_DIR)/sample-mermaid-test.pdf
	@rm -rf build/
	@echo "==> Cleaned"

# ------------------------------------------------------------------------------
# Version management (mirrors project-template pattern)
# ------------------------------------------------------------------------------
.PHONY: version
version: ## Show current version from VERSION file
	@echo "$(VERSION)"

.PHONY: version-bump-patch
version-bump-patch: ## Bump patch (0.0.X) → commit
	@current="$$(cat VERSION)"; \
	major="$${current%%.*}"; rest="$${current#*.}"; \
	minor="$${rest%%.*}"; patch="$${rest#*.}"; \
	new="$$major.$$minor.$$((patch + 1))"; \
	echo "$$new" > VERSION; \
	$(GIT) add VERSION; \
	$(GIT) commit -m "chore: bump version to v$$new"; \
	echo "==> Bumped: $$current → v$$new"; \
	echo "    Next: make tag"

.PHONY: version-bump-minor
version-bump-minor: ## Bump minor (0.X.0) → commit
	@current="$$(cat VERSION)"; \
	major="$${current%%.*}"; rest="$${current#*.}"; \
	minor="$${rest%%.*}"; \
	new="$$major.$$((minor + 1)).0"; \
	echo "$$new" > VERSION; \
	$(GIT) add VERSION; \
	$(GIT) commit -m "chore: bump version to v$$new"; \
	echo "==> Bumped: $$current → v$$new"; \
	echo "    Next: make tag"

.PHONY: version-bump-major
version-bump-major: ## Bump major (X.0.0) → commit
	@current="$$(cat VERSION)"; \
	major="$${current%%.*}"; \
	new="$$((major + 1)).0.0"; \
	echo "$$new" > VERSION; \
	$(GIT) add VERSION; \
	$(GIT) commit -m "chore: bump version to v$$new"; \
	echo "==> Bumped: $$current → v$$new"; \
	echo "    Next: make tag"

# ------------------------------------------------------------------------------
# Tag / Release
# ------------------------------------------------------------------------------
.PHONY: tag
tag: ## Create annotated git tag from VERSION (guards: clean tree + committed)
	@if [[ -z "$(GIT)" ]]; then echo "Error: git not found"; exit 1; fi; \
	version="$$(cat VERSION)"; \
	tag="v$$version"; \
	if ! $(GIT) diff --quiet HEAD 2>/dev/null; then \
		echo "Error: working tree is dirty — commit all changes before tagging"; \
		$(GIT) status -sb; exit 1; \
	fi; \
	committed="$$($(GIT) show HEAD:VERSION 2>/dev/null | tr -d '[:space:]')"; \
	if [[ "$$committed" != "$$version" ]]; then \
		echo "Error: VERSION ($$version) not yet committed (HEAD has: $$committed)"; \
		echo "       Run: git add VERSION && git commit"; exit 1; \
	fi; \
	if $(GIT) rev-parse "$$tag" >/dev/null 2>&1; then \
		echo "Error: tag $$tag already exists"; exit 1; \
	fi; \
	$(GIT) tag -a "$$tag" -m "Release $$tag"; \
	echo "==> Created tag $$tag"; \
	echo "    Next: git push origin master && git push origin $$tag"

.PHONY: release
release: ## Full patch release: bump patch → commit → tag
	@echo "==> Starting patch release from v$(VERSION)..."
	@$(MAKE) --no-print-directory version-bump-patch
	@$(MAKE) --no-print-directory tag
	@version="$$(cat VERSION)"; \
	echo "==> Release v$$version complete!"; \
	echo "    Next: git push origin master && git push origin v$$version"

# ------------------------------------------------------------------------------
# Utility
# ------------------------------------------------------------------------------
.PHONY: status
status: ## Show git status and current version
	@echo "Version : $(VERSION)"
	@echo "Variant : $(VARIANT)"
	@if [[ -n "$(GIT)" ]]; then echo ""; $(GIT) status -sb; fi

.PHONY: shell
shell: ## Open interactive shell in the dev-VARIANT container
	@docker run -it --rm \
		-v "$(PWD):/workdir:z" \
		--entrypoint sh \
		$(IMAGE_NAME):dev-$(VARIANT)

# --- EOF ----------------------------------------------------------------------
