#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-19
# Revision...: 2.0.0
# Purpose....: Build multi-arch Docker image for Pandoc + TinyTeX + MS fonts
# Notes......: Supports multi-platform builds with buildx
#              Separated from test/sample generation for focused responsibility
# Reference..: https://github.com/oehrlis/docker-pandoc
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# Function: err
# Purpose.: Print error message to stderr and exit
# Args....: $* - Error message
# Returns.: Exits with code 1
# ------------------------------------------------------------------------------
err() {
  echo "Error: $*" >&2
  exit 1
}

# ------------------------------------------------------------------------------
# Function: log_info
# Purpose.: Print informational message
# Args....: $* - Message to print
# Returns.: 0
# ------------------------------------------------------------------------------
log_info() {
  echo "==> $*"
}

# ------------------------------------------------------------------------------
# Function: log_detail
# Purpose.: Print detailed/indented message
# Args....: $* - Message to print
# Returns.: 0
# ------------------------------------------------------------------------------
log_detail() {
  echo "    $*"
}

# ------------------------------------------------------------------------------
# Function: need
# Purpose.: Check if a required command is available
# Args....: $1 - Command name to check
# Returns.: 0 if command exists, exits with error if not
# ------------------------------------------------------------------------------
need() {
  command -v "$1" >/dev/null 2>&1 || err "Missing required command: $1"
}

# ------------------------------------------------------------------------------
# Function: usage
# Purpose.: Display script usage information
# Returns.: 0
# ------------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [RELEASE] [options]

Build multi-arch Docker image for Pandoc with TinyTeX and MS fonts.

Positional:
  RELEASE               Tag to build (default: beta). Examples: beta, 1.2.3

Options:
  --no-cache            Build without cache
  --local|--load        Local-only build (use --load, do not push)
  --push                Force push to registry (default behavior)
  --platform=LIST       Target platforms (default: linux/amd64,linux/arm64)
  -h, --help            Show this help

Examples:
  $(basename "$0")                      # Build beta tag, push to registry
  $(basename "$0") 1.2.3 --push         # Build version 1.2.3 and push
  $(basename "$0") beta --local         # Build beta locally only
  $(basename "$0") 1.2.3 --no-cache     # Build without cache

EOF
}

# ------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose.: Parse command-line arguments
# Args....: $@ - All command-line arguments
# Returns.: 0 on success
# Output..: Sets global variables for script configuration
# ------------------------------------------------------------------------------
parse_arguments() {
  for arg in "$@"; do
    case "${arg}" in
      -h | --help)
        usage
        exit 0
        ;;
      --no-cache)
        USE_NO_CACHE=1
        ;;
      --local | --load)
        LOCAL_BUILD=1
        DO_PUSH=0
        ;;
      --push)
        LOCAL_BUILD=0
        DO_PUSH=1
        ;;
      --platform=*)
        PLATFORM="${arg#*=}"
        ;;
      --*)
        err "Unknown option: ${arg}. Use --help for usage."
        ;;
      *)
        RELEASE="${arg}"
        ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Function: validate_environment
# Purpose.: Validate required environment variables and commands
# Returns.: 0 on success, exits on error
# ------------------------------------------------------------------------------
validate_environment() {
  : "${DOCKER_USER:?DOCKER_USER must be set}"
  : "${IMAGE:?IMAGE must resolve from project folder name}"

  need docker
  need git
}

# ------------------------------------------------------------------------------
# Function: setup_build_context
# Purpose.: Set up build context and derive project information
# Returns.: 0 on success
# Output..: Sets BUILD_CONTEXT, PROJECT, IMAGE variables
# ------------------------------------------------------------------------------
setup_build_context() {
  local _build_dir
  _build_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
  export BUILD_CONTEXT="${_build_dir}"
  export PROJECT
  PROJECT="$(basename "${BUILD_CONTEXT}")"

  # Derive image name; fallback to folder name if no dash present
  if [[ "${PROJECT}" == *-* ]]; then
    IMAGE="$(echo "${PROJECT}" | cut -d- -f2)"
  else
    IMAGE="${PROJECT}"
  fi
  export IMAGE
}

# ------------------------------------------------------------------------------
# Function: determine_local_platform
# Purpose.: Determine the local platform for --load builds
# Returns.: 0 on success
# Output..: Prints the platform string
# ------------------------------------------------------------------------------
determine_local_platform() {
  local platform
  platform="$(uname -m)"
  case "${platform}" in
    x86_64) echo "linux/amd64" ;;
    aarch64 | arm64) echo "linux/arm64" ;;
    *) err "Unsupported local platform: ${platform}" ;;
  esac
}

# ------------------------------------------------------------------------------
# Function: build_tags_array
# Purpose.: Build array of Docker tags based on release version
# Args....: $1 - Release version
# Returns.: 0 on success
# Output..: Populates TAG_OPTS array
# ------------------------------------------------------------------------------
build_tags_array() {
  local release="$1"
  TAG_OPTS=()

  if [[ "${release}" == "beta" ]]; then
    TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:${release}")
  else
    TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:${release}")
    TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:latest")
    TAG_OPTS+=(-t "${DOCKER_USER}/${IMAGE}:texlive-slim")
  fi
}

# ------------------------------------------------------------------------------
# Function: build_image_local
# Purpose.: Build Docker image locally with --load
# Returns.: 0 on success
# ------------------------------------------------------------------------------
build_image_local() {
  local local_platform
  local_platform="$(determine_local_platform)"

  log_info "LOCAL build (--load)"
  log_detail "Single platform: ${local_platform}"

  # Override platform for local build
  local local_build_opts=("${BUILD_OPTS[@]}")
  local idx
  for idx in "${!local_build_opts[@]}"; do
    if [[ "${local_build_opts[${idx}]}" == --platform=* ]]; then
      local_build_opts[${idx}]="--platform=${local_platform}"
    fi
  done

  docker buildx build --load "${TAG_OPTS[@]}" "${local_build_opts[@]}" .
}

# ------------------------------------------------------------------------------
# Function: build_image_push
# Purpose.: Build Docker image and push to registry
# Returns.: 0 on success
# ------------------------------------------------------------------------------
build_image_push() {
  log_info "REGISTRY build (--push)"
  docker buildx build --push "${TAG_OPTS[@]}" "${BUILD_OPTS[@]}" .

  log_info "Pulling ${DOCKER_USER}/${IMAGE}:${RELEASE}"
  docker pull "${DOCKER_USER}/${IMAGE}:${RELEASE}"
}

# ------------------------------------------------------------------------------
# Function: print_build_summary
# Purpose.: Print build configuration summary
# Returns.: 0
# ------------------------------------------------------------------------------
print_build_summary() {
  local mode cache
  if [[ ${LOCAL_BUILD} -eq 1 ]]; then
    mode='LOCAL (--load)'
  else
    mode='REGISTRY (--push)'
  fi
  if [[ ${USE_NO_CACHE} -eq 1 ]]; then
    cache='disabled'
  else
    cache='enabled'
  fi

  log_info "Building '${DOCKER_USER}/${IMAGE}'"
  log_detail "Release: ${RELEASE}"
  log_detail "Mode:    ${mode}"
  log_detail "Cache:   ${cache}"
  log_detail "Platf.:  ${PLATFORM}"
  log_info "Tags:"
  for tag in "${TAG_OPTS[@]}"; do
    if [[ "${tag}" == -t ]]; then
      continue
    fi
    log_detail "${tag}"
  done
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose.: Main entry point for the script
# Args....: $@ - All command-line arguments
# Returns.: 0 on success, 1 on error
# ------------------------------------------------------------------------------
main() {
  # Set defaults
  export DOCKER_USER="${DOCKER_USER:-oehrlis}"
  RELEASE="beta"
  USE_NO_CACHE=0
  LOCAL_BUILD=0
  DO_PUSH=1
  PLATFORM="linux/amd64,linux/arm64"

  # Setup build context
  setup_build_context

  # Parse command-line arguments
  parse_arguments "$@"

  # Validate environment
  validate_environment

  # Save current directory and change to build context
  local current_path
  current_path="$(pwd)"
  cd "${BUILD_CONTEXT}" || err "Failed to change to build context"

  # Build tags array
  build_tags_array "${RELEASE}"

  # Build options array
  BUILD_OPTS=(
    --build-arg "SLIM_TEX=1"
    --build-arg "PRUNE_MS_FONTS=1"
    --platform="${PLATFORM}"
    --network=host
    --build-arg "BUILDKIT_INLINE_CACHE=1"
  )
  [[ ${USE_NO_CACHE} -eq 1 ]] && BUILD_OPTS+=(--no-cache)

  # Print build summary
  print_build_summary

  # Execute build
  if [[ ${LOCAL_BUILD} -eq 1 ]]; then
    build_image_local
  else
    build_image_push
  fi

  # Return to original directory
  cd "${current_path}" || err "Failed to return to original directory"

  log_info "Build completed."
}

# Run main function
main "$@"
# --- EOF ----------------------------------------------------------------------
