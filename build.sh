#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2026-01-19
# Revision...: 2.0.0
# Purpose....: Wrapper script for backwards compatibility
# Notes......: Delegates to scripts/build.sh and scripts/test.sh
#              Maintains compatibility with old --test/--no-test options
# Reference..: https://github.com/oehrlis/docker-pandoc
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# Parse arguments to separate build args from test flag
BUILD_ARGS=()
TEST=1

for arg in "$@"; do
  case "${arg}" in
    --test)
      TEST=1
      ;;
    --no-test)
      TEST=0
      ;;
    *)
      BUILD_ARGS+=("${arg}")
      ;;
  esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Call the new build script
"${SCRIPT_DIR}/scripts/build.sh" "${BUILD_ARGS[@]}"

# Call test script if requested
if [[ ${TEST} -eq 1 ]]; then
  # Extract release tag from build args (first non-option argument)
  RELEASE="beta"
  for arg in "${BUILD_ARGS[@]}"; do
    if [[ "${arg}" != --* ]]; then
      RELEASE="${arg}"
      break
    fi
  done
  "${SCRIPT_DIR}/scripts/test.sh" "${RELEASE}"
fi

# --- EOF ----------------------------------------------------------------------
