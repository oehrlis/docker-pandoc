#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-19
# Revision...: 1.0.0
# Purpose....: Test Docker image by generating sample documents
# Notes......: Tests PDF, DOCX, PPTX generation and Mermaid diagram rendering
#              Separated from build for focused responsibility
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
Usage: $(basename "$0") [RELEASE]

Generate sample documents to test Docker image functionality.

Positional:
  RELEASE               Tag to test (default: beta). Examples: beta, 1.2.3

Options:
  -h, --help            Show this help

Tests:
  - PDF generation with XeLaTeX
  - DOCX generation
  - PPTX generation
  - Mermaid diagram rendering in PDF

Examples:
  $(basename "$0")           # Test beta tag
  $(basename "$0") 1.2.3     # Test version 1.2.3

EOF
}

# ------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose.: Parse command-line arguments
# Args....: $@ - All command-line arguments
# Returns.: 0 on success
# Output..: Sets RELEASE variable
# ------------------------------------------------------------------------------
parse_arguments() {
  for arg in "$@"; do
    case "${arg}" in
      -h | --help)
        usage
        exit 0
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
# Function: verify_image_exists
# Purpose.: Check if Docker image exists locally
# Args....: $1 - Image tag
# Returns.: 0 if exists, 1 otherwise
# ------------------------------------------------------------------------------
verify_image_exists() {
  local image_tag="$1"
  docker image inspect "${image_tag}" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Function: generate_pdf_sample
# Purpose.: Generate PDF sample document
# Args....: $1 - Docker image tag
# Returns.: 0 on success
# ------------------------------------------------------------------------------
generate_pdf_sample() {
  local image_tag="$1"
  local run_opts=(-v "${PWD}:/workdir:z" "${image_tag}")

  log_detail "PDF"
  docker run --rm "${run_opts[@]}" \
    --metadata-file sample/metadata.yml --filter pandoc-latex-environment \
    --resource-path=sample --pdf-engine=xelatex \
    -o sample/sample.pdf sample/sample.md
}

# ------------------------------------------------------------------------------
# Function: generate_docx_sample
# Purpose.: Generate DOCX sample document
# Args....: $1 - Docker image tag
# Returns.: 0 on success
# ------------------------------------------------------------------------------
generate_docx_sample() {
  local image_tag="$1"
  local run_opts=(-v "${PWD}:/workdir:z" "${image_tag}")

  log_detail "DOCX"
  docker run --rm "${run_opts[@]}" \
    --metadata-file sample/metadata.yml --resource-path=sample \
    -o sample/sample.docx sample/sample.md
}

# ------------------------------------------------------------------------------
# Function: generate_pptx_sample
# Purpose.: Generate PPTX sample document
# Args....: $1 - Docker image tag
# Returns.: 0 on success
# ------------------------------------------------------------------------------
generate_pptx_sample() {
  local image_tag="$1"
  local run_opts=(-v "${PWD}:/workdir:z" "${image_tag}")

  log_detail "PPTX"
  docker run --rm "${run_opts[@]}" \
    --metadata-file sample/metadata.yml --resource-path=sample \
    -o sample/sample.pptx sample/sample.md
}

# ------------------------------------------------------------------------------
# Function: generate_mermaid_test
# Purpose.: Generate Mermaid diagram test PDF
# Args....: $1 - Docker image tag
# Returns.: 0 on success
# ------------------------------------------------------------------------------
generate_mermaid_test() {
  local image_tag="$1"
  local run_opts=(-v "${PWD}:/workdir:z" "${image_tag}")

  log_detail "Mermaid PDF Test"
  docker run --rm "${run_opts[@]}" \
    examples/test-mermaid.md \
    -o examples/test-output.pdf \
    --lua-filter /usr/local/share/pandoc/filters/mermaid.lua \
    --pdf-engine=xelatex \
    --toc
  log_detail "Test complete. Check examples/test-output.pdf"
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

  # Setup build context
  setup_build_context

  # Parse command-line arguments
  parse_arguments "$@"

  # Validate environment
  validate_environment

  # Save current directory and change to build context
  local current_path image_tag
  current_path="$(pwd)"
  cd "${BUILD_CONTEXT}" || err "Failed to change to build context"

  image_tag="${DOCKER_USER}/${IMAGE}:${RELEASE}"

  # Verify image exists
  if verify_image_exists "${image_tag}"; then
    : # Image exists, continue
  else
    err "Docker image ${image_tag} not found. Build it first with scripts/build.sh"
  fi

  log_info "Testing ${image_tag}"
  log_info "Generating sample documents"

  # Generate all samples
  generate_pdf_sample "${image_tag}"
  generate_docx_sample "${image_tag}"
  generate_pptx_sample "${image_tag}"
  generate_mermaid_test "${image_tag}"

  # Return to original directory
  cd "${current_path}" || err "Failed to return to original directory"

  log_info "All tests completed successfully."
}

# Run main function
main "$@"
# --- EOF ----------------------------------------------------------------------
