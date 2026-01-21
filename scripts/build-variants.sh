#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build-variants.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-21
# Revision...: 1.0.0
# Purpose....: Build all Pandoc Docker image variants
# Notes......: Creates minimal, standard, full, and mermaid variants
#              Each variant has different features and size tradeoffs
# Reference..: https://github.com/oehrlis/docker-pandoc
# License....: Apache License Version 2.0, January 2004
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
IMAGE_NAME="${IMAGE_NAME:-oehrlis/pandoc}"
VERSION="${VERSION:-$(cat VERSION 2>/dev/null || echo "dev")}"
PLATFORM="${PLATFORM:-linux/arm64}"  # Default to current platform for testing
PUSH="${PUSH:-false}"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------
log_info() {
  echo "==> $*"
}

log_detail() {
  echo "    $*"
}

err() {
  echo "Error: $*" >&2
  exit 1
}

# ------------------------------------------------------------------------------
# Function: build_variant
# Purpose.: Build a specific image variant
# Args....: $1 - Variant name (minimal|standard|full|mermaid)
#           $2 - Expected size description
# ------------------------------------------------------------------------------
build_variant() {
  local variant="$1"
  local size_desc="$2"
  local tag="${IMAGE_NAME}:${VERSION}-${variant}"
  
  log_info "Building ${variant} variant"
  log_detail "Tag: ${tag}"
  log_detail "Expected size: ${size_desc}"
  log_detail "Platform: ${PLATFORM}"
  
  local build_args=(
    "--platform" "${PLATFORM}"
    "--build-arg" "IMAGE_VARIANT=${variant}"
    "-t" "${tag}"
  )
  
  if [ "${PUSH}" = "true" ]; then
    build_args+=("--push")
  else
    build_args+=("--load")
  fi
  
  if docker build "${build_args[@]}" . ; then
    log_info "✓ Successfully built ${variant} variant"
    
    # Show size if loaded locally
    if [ "${PUSH}" != "true" ]; then
      local size=$(docker images "${tag}" --format "{{.Size}}" 2>/dev/null || echo "unknown")
      log_detail "Actual size: ${size}"
    fi
  else
    err "Failed to build ${variant} variant"
  fi
  
  echo ""
}

# ------------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------------
main() {
  log_info "Building Pandoc Docker image variants"
  log_detail "Base image: ${IMAGE_NAME}"
  log_detail "Version: ${VERSION}"
  log_detail "Platform: ${PLATFORM}"
  log_detail "Push: ${PUSH}"
  echo ""
  
  # Build each variant
  build_variant "minimal" "~250MB" \
    "Pandoc only, no TeX, no Mermaid"
  
  build_variant "standard" "~800MB-1GB" \
    "Pandoc + TeX Live (default)"
  
  build_variant "mermaid" "~900MB-1GB" \
    "Pandoc + Mermaid, no TeX"
  
  build_variant "full" "~1.3-1.5GB" \
    "Pandoc + TeX + Mermaid"
  
  # Summary
  log_info "Build Summary"
  if [ "${PUSH}" != "true" ]; then
    docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
      grep -E "(REPOSITORY|${VERSION})" || true
  fi
  
  log_info "All variants built successfully!"
  echo ""
  log_info "Usage examples:"
  log_detail "Minimal:  docker run --rm ${IMAGE_NAME}:${VERSION}-minimal -h"
  log_detail "Standard: docker run --rm ${IMAGE_NAME}:${VERSION}-standard -h"
  log_detail "Mermaid:  docker run --rm ${IMAGE_NAME}:${VERSION}-mermaid -h"
  log_detail "Full:     docker run --rm ${IMAGE_NAME}:${VERSION}-full -h"
}

# Run main
main "$@"
