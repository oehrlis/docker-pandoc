#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: release.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-19
# Revision...: 2.0.0
# Purpose....: Release Docker image with version bumping and git tagging
# Notes......: Handles version bumping (major/minor/patch), builds image,
#              commits changes, and pushes tags to trigger release workflow
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
Usage: $(basename "$0") [RELEASE_TYPE] [BUILD_OPTIONS]

Release Docker image with version bumping and git tagging.

Positional:
  RELEASE_TYPE          Version bump type: major, minor, patch (default: patch)

Build Options:
  --no-cache            Build without cache (passed to build.sh)
  --local|--load        Local-only build, do not push (passed to build.sh)
  --push                Force push to registry (passed to build.sh)

Other Options:
  -h, --help            Show this help

Examples:
  $(basename "$0")                      # Bump patch version and release
  $(basename "$0") minor                # Bump minor version and release
  $(basename "$0") major --no-cache     # Bump major version, build without cache

Notes:
  - Requires treeder/bump Docker image for version bumping
  - Pulls latest changes from git before bumping
  - Creates git commit and tag with new version
  - Pushes commits and tags to trigger CI/CD release workflow

EOF
}

# ------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose.: Parse command-line arguments
# Args....: $@ - All command-line arguments
# Returns.: 0 on success
# Output..: Sets global variables REL_TYPE and BUILD_ARGS
# ------------------------------------------------------------------------------
parse_arguments() {
  local first_arg_processed=0
  BUILD_ARGS=()

  for arg in "$@"; do
    case "${arg}" in
      -h | --help)
        usage
        exit 0
        ;;
      --no-cache | --local | --load | --push)
        BUILD_ARGS+=("${arg}")
        ;;
      --*)
        err "Unknown option: ${arg}. Use --help for usage."
        ;;
      major | minor | patch)
        if [[ ${first_arg_processed} -eq 0 ]]; then
          REL_TYPE="${arg}"
          first_arg_processed=1
        else
          err "Multiple release types specified. Use --help for usage."
        fi
        ;;
      *)
        err "Unknown argument: ${arg}. Use --help for usage."
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
  export IMAGE

  # Derive image name; fallback to folder name if no dash present
  if [[ "${PROJECT}" == *-* ]]; then
    IMAGE="$(echo "${PROJECT}" | cut -d- -f2)"
  else
    IMAGE="${PROJECT}"
  fi
}

# ------------------------------------------------------------------------------
# Function: sync_repository
# Purpose.: Ensure repository is up to date with remote
# Returns.: 0 on success
# ------------------------------------------------------------------------------
sync_repository() {
  log_info "Syncing repository with remote"
  git pull || err "Failed to pull from remote repository"
}

# ------------------------------------------------------------------------------
# Function: bump_version
# Purpose.: Bump version using treeder/bump Docker image
# Args....: $1 - Release type (major/minor/patch)
# Returns.: 0 on success
# Output..: Prints old and new version
# ------------------------------------------------------------------------------
bump_version() {
  local rel_type="$1"
  local pre_version new_version

  pre_version="$(cat VERSION 2>/dev/null || echo "0.0.0")"
  log_info "Current version: ${pre_version}"

  docker run --rm -v "${PWD}":/app treeder/bump "${rel_type}" ||
    err "Failed to bump version with treeder/bump"

  new_version="$(cat VERSION 2>/dev/null || err "VERSION file not found after bump")"
  log_info "New version: ${new_version}"

  echo "${new_version}"
}

# ------------------------------------------------------------------------------
# Function: build_release
# Purpose.: Build Docker image for the release
# Args....: $1 - Version string
#           $@ - Additional build arguments
# Returns.: 0 on success
# ------------------------------------------------------------------------------
build_release() {
  local version="$1"
  shift
  local build_args=("$@")

  log_info "Building release ${version}"

  # Call the build script from scripts directory
  local build_script="${BUILD_CONTEXT}/scripts/build.sh"
  if [[ ! -x "${build_script}" ]]; then
    err "Build script not found or not executable: ${build_script}"
  fi

  "${build_script}" "${version}" "${build_args[@]}" ||
    err "Build failed for version ${version}"
}

# ------------------------------------------------------------------------------
# Function: tag_and_push
# Purpose.: Create git commit and tag, then push to remote
# Args....: $1 - Version string
# Returns.: 0 on success
# ------------------------------------------------------------------------------
tag_and_push() {
  local version="$1"

  log_info "Tagging release ${version}"

  git add -A || err "Failed to stage changes"
  git commit -m "version ${version}" || err "Failed to commit changes"
  git tag -a "${version}" -m "version ${version}" || err "Failed to create tag"

  log_info "Pushing commits and tags"
  git push || err "Failed to push commits"
  git push --tags || err "Failed to push tags"

  log_info "Tag ${version} pushed successfully"
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
  REL_TYPE="patch"
  BUILD_ARGS=()

  # Setup build context
  setup_build_context

  # Parse command-line arguments
  parse_arguments "$@"

  # Validate environment
  validate_environment

  # Save current directory and change to build context
  local current_path version
  current_path="$(pwd)"
  cd "${BUILD_CONTEXT}" || err "Failed to change to build context"

  # Sync with remote
  sync_repository

  # Bump version
  version="$(bump_version "${REL_TYPE}")"

  # Build release
  build_release "${version}" "${BUILD_ARGS[@]}"

  # Tag and push
  tag_and_push "${version}"

  # Return to original directory
  cd "${current_path}" || err "Failed to return to original directory"

  log_info "Release ${version} completed successfully."
}

# Run main function
main "$@"
# --- EOF ----------------------------------------------------------------------
